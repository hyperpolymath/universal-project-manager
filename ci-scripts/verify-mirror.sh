#!/usr/bin/env bash
# Mirror Verification Script
# Verifies that two git remotes are in sync
# Exit codes: 0 = in sync, 1 = out of sync, 2 = error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Configuration
SOURCE_REMOTE="${SOURCE_REMOTE:-origin}"
MIRROR_REMOTE="${MIRROR_REMOTE:-gitlab}"
VERBOSE="${VERBOSE:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Fetch latest from remotes
fetch_remotes() {
    log_info "Fetching from remotes..."

    git fetch "$SOURCE_REMOTE" --prune --tags 2>/dev/null || {
        log_error "Failed to fetch from $SOURCE_REMOTE"
        return 1
    }

    git fetch "$MIRROR_REMOTE" --prune --tags 2>/dev/null || {
        log_warn "Failed to fetch from $MIRROR_REMOTE (may not be configured)"
        return 1
    }

    log_success "Fetched from both remotes"
}

# Compare branches between remotes
compare_branches() {
    log_info "Comparing branches..."

    local source_branches mirror_branches
    local missing_in_mirror=()
    local missing_in_source=()
    local out_of_sync=()

    # Get branch lists
    source_branches=$(git branch -r | grep "^  $SOURCE_REMOTE/" | sed "s|  $SOURCE_REMOTE/||" | grep -v HEAD || true)
    mirror_branches=$(git branch -r | grep "^  $MIRROR_REMOTE/" | sed "s|  $MIRROR_REMOTE/||" | grep -v HEAD || true)

    # Check for branches missing in mirror
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        if ! echo "$mirror_branches" | grep -q "^$branch$"; then
            missing_in_mirror+=("$branch")
        fi
    done <<< "$source_branches"

    # Check for branches missing in source
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        if ! echo "$source_branches" | grep -q "^$branch$"; then
            missing_in_source+=("$branch")
        fi
    done <<< "$mirror_branches"

    # Check for branches that exist in both but are out of sync
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        if echo "$mirror_branches" | grep -q "^$branch$"; then
            local source_sha mirror_sha
            source_sha=$(git rev-parse "$SOURCE_REMOTE/$branch" 2>/dev/null || echo "")
            mirror_sha=$(git rev-parse "$MIRROR_REMOTE/$branch" 2>/dev/null || echo "")

            if [[ -n "$source_sha" && -n "$mirror_sha" && "$source_sha" != "$mirror_sha" ]]; then
                out_of_sync+=("$branch")
            fi
        fi
    done <<< "$source_branches"

    # Report results
    echo ""
    echo "========================================"
    echo "         BRANCH COMPARISON"
    echo "========================================"
    echo ""

    if [[ ${#missing_in_mirror[@]} -gt 0 ]]; then
        log_warn "Branches missing in $MIRROR_REMOTE:"
        printf '  - %s\n' "${missing_in_mirror[@]}"
        echo ""
    fi

    if [[ ${#missing_in_source[@]} -gt 0 ]]; then
        log_warn "Branches missing in $SOURCE_REMOTE:"
        printf '  - %s\n' "${missing_in_source[@]}"
        echo ""
    fi

    if [[ ${#out_of_sync[@]} -gt 0 ]]; then
        log_error "Branches out of sync:"
        printf '  - %s\n' "${out_of_sync[@]}"
        echo ""
    fi

    local total_issues=$((${#missing_in_mirror[@]} + ${#missing_in_source[@]} + ${#out_of_sync[@]}))

    if [[ $total_issues -eq 0 ]]; then
        log_success "All branches are in sync!"
        return 0
    else
        return 1
    fi
}

# Compare tags between remotes
compare_tags() {
    log_info "Comparing tags..."

    local source_tags mirror_tags
    local missing_in_mirror=()
    local missing_in_source=()
    local tag_mismatch=()

    # Get tag lists
    source_tags=$(git tag -l --sort=-creatordate 2>/dev/null || true)

    # Get tags from mirror remote
    mirror_tags=$(git ls-remote --tags "$MIRROR_REMOTE" 2>/dev/null | awk '{print $2}' | sed 's|refs/tags/||' | grep -v '\^{}' || true)

    # For this check, we'll compare local tags (which should be from source)
    # with what the mirror reports

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        if ! echo "$mirror_tags" | grep -q "^$tag$"; then
            missing_in_mirror+=("$tag")
        fi
    done <<< "$source_tags"

    # Report results
    echo ""
    echo "========================================"
    echo "          TAG COMPARISON"
    echo "========================================"
    echo ""

    local source_count mirror_count
    source_count=$(echo "$source_tags" | grep -c . || echo 0)
    mirror_count=$(echo "$mirror_tags" | grep -c . || echo 0)

    echo "Tags in $SOURCE_REMOTE: $source_count"
    echo "Tags in $MIRROR_REMOTE: $mirror_count"
    echo ""

    if [[ ${#missing_in_mirror[@]} -gt 0 ]]; then
        log_warn "Tags missing in $MIRROR_REMOTE (first 10):"
        printf '  - %s\n' "${missing_in_mirror[@]:0:10}"
        [[ ${#missing_in_mirror[@]} -gt 10 ]] && echo "  ... and $((${#missing_in_mirror[@]} - 10)) more"
        echo ""
        return 1
    else
        log_success "All tags are in sync!"
        return 0
    fi
}

# Verify commit history integrity
verify_history() {
    log_info "Verifying commit history integrity..."

    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/"$SOURCE_REMOTE"/HEAD 2>/dev/null | sed "s|refs/remotes/$SOURCE_REMOTE/||" || echo "main")

    if ! git rev-parse "$SOURCE_REMOTE/$default_branch" &>/dev/null; then
        default_branch="master"
    fi

    echo ""
    echo "========================================"
    echo "        HISTORY VERIFICATION"
    echo "========================================"
    echo ""
    echo "Default branch: $default_branch"

    # Get commit counts
    local source_commits
    source_commits=$(git rev-list --count "$SOURCE_REMOTE/$default_branch" 2>/dev/null || echo 0)
    echo "Commits in $SOURCE_REMOTE/$default_branch: $source_commits"

    if git rev-parse "$MIRROR_REMOTE/$default_branch" &>/dev/null; then
        local mirror_commits
        mirror_commits=$(git rev-list --count "$MIRROR_REMOTE/$default_branch" 2>/dev/null || echo 0)
        echo "Commits in $MIRROR_REMOTE/$default_branch: $mirror_commits"

        if [[ "$source_commits" -eq "$mirror_commits" ]]; then
            log_success "Commit counts match!"
        else
            log_warn "Commit counts differ (source: $source_commits, mirror: $mirror_commits)"
        fi
    else
        log_warn "Cannot find $MIRROR_REMOTE/$default_branch"
    fi

    # Verify latest commit SHA matches
    local source_head mirror_head
    source_head=$(git rev-parse "$SOURCE_REMOTE/$default_branch" 2>/dev/null || echo "unknown")
    mirror_head=$(git rev-parse "$MIRROR_REMOTE/$default_branch" 2>/dev/null || echo "unknown")

    echo ""
    echo "Latest commit on $SOURCE_REMOTE/$default_branch: ${source_head:0:12}"
    echo "Latest commit on $MIRROR_REMOTE/$default_branch: ${mirror_head:0:12}"

    if [[ "$source_head" == "$mirror_head" ]]; then
        log_success "HEAD commits match!"
        return 0
    else
        log_error "HEAD commits differ!"
        return 1
    fi
}

# Generate verification report
generate_report() {
    local report_file="$PROJECT_ROOT/mirror-verification-report.txt"

    {
        echo "Mirror Verification Report"
        echo "=========================="
        echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""
        echo "Source Remote: $SOURCE_REMOTE"
        echo "Mirror Remote: $MIRROR_REMOTE"
        echo ""

        echo "Remote URLs:"
        git remote -v
        echo ""

        echo "Branches:"
        git branch -r
        echo ""

        echo "Tags (last 20):"
        git tag -l --sort=-creatordate | head -20
        echo ""

        echo "Recent commits (source):"
        git log --oneline -10 "$SOURCE_REMOTE/$(git symbolic-ref refs/remotes/$SOURCE_REMOTE/HEAD 2>/dev/null | sed "s|refs/remotes/$SOURCE_REMOTE/||" || echo main)" 2>/dev/null || echo "N/A"

    } > "$report_file"

    log_info "Report saved to: $report_file"
}

# Main function
main() {
    cd "$PROJECT_ROOT"

    log_info "Starting mirror verification"
    log_info "Source remote: $SOURCE_REMOTE"
    log_info "Mirror remote: $MIRROR_REMOTE"
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source) SOURCE_REMOTE="$2"; shift 2 ;;
            --mirror) MIRROR_REMOTE="$2"; shift 2 ;;
            --verbose|-v) VERBOSE="true"; shift ;;
            --report) generate_report; shift ;;
            *) shift ;;
        esac
    done

    local exit_code=0

    # Run verification steps
    fetch_remotes || exit_code=2

    if [[ $exit_code -eq 0 ]]; then
        compare_branches || exit_code=1
        compare_tags || exit_code=1
        verify_history || exit_code=1
    fi

    echo ""
    echo "========================================"
    echo "          FINAL RESULT"
    echo "========================================"

    case $exit_code in
        0) log_success "Mirror verification passed! All remotes are in sync." ;;
        1) log_warn "Mirror verification found discrepancies." ;;
        2) log_error "Mirror verification failed due to errors." ;;
    esac

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
