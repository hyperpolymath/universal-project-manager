#!/usr/bin/env bash
# Mirror Sync Script
# Syncs branches and tags between GitHub (origin) and GitLab (mirror)
# Designed to be triggered by GitHub Actions on push events (event-driven, not polling)
# Exit codes: 0 = success, 1 = error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Configuration
SOURCE_REMOTE="${SOURCE_REMOTE:-origin}"
MIRROR_REMOTE="${MIRROR_REMOTE:-gitlab}"
MIRROR_URL="${MIRROR_URL:-}"
DRY_RUN="${DRY_RUN:-false}"

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

# Setup mirror remote
setup_mirror_remote() {
    log_info "Setting up mirror remote..."

    if [[ -z "$MIRROR_URL" ]]; then
        log_error "MIRROR_URL environment variable is required"
        return 1
    fi

    # Add or update mirror remote
    if git remote get-url "$MIRROR_REMOTE" &>/dev/null; then
        git remote set-url "$MIRROR_REMOTE" "$MIRROR_URL"
        log_info "Updated $MIRROR_REMOTE URL to $MIRROR_URL"
    else
        git remote add "$MIRROR_REMOTE" "$MIRROR_URL"
        log_info "Added $MIRROR_REMOTE remote: $MIRROR_URL"
    fi
}

# Sync specific branch
sync_branch() {
    local branch="$1"

    log_info "Syncing branch: $branch"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would push $branch to $MIRROR_REMOTE"
        return 0
    fi

    if git push "$MIRROR_REMOTE" "$SOURCE_REMOTE/$branch:refs/heads/$branch" --force; then
        log_success "Synced branch: $branch"
        return 0
    else
        log_error "Failed to sync branch: $branch"
        return 1
    fi
}

# Sync all branches
sync_all_branches() {
    log_info "Syncing all branches..."

    local branches
    branches=$(git branch -r | grep "^  $SOURCE_REMOTE/" | sed "s|  $SOURCE_REMOTE/||" | grep -v HEAD || true)

    local success=0
    local failed=0

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        if sync_branch "$branch"; then
            ((success++)) || true
        else
            ((failed++)) || true
        fi
    done <<< "$branches"

    echo ""
    log_info "Branch sync complete: $success succeeded, $failed failed"

    [[ $failed -gt 0 ]] && return 1
    return 0
}

# Sync all tags
sync_tags() {
    log_info "Syncing tags..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would push all tags to $MIRROR_REMOTE"
        return 0
    fi

    if git push "$MIRROR_REMOTE" --tags --force; then
        log_success "Tags synced successfully"
        return 0
    else
        log_error "Failed to sync tags"
        return 1
    fi
}

# Sync triggered by push event (event-driven)
sync_on_push() {
    local ref="${GITHUB_REF:-}"
    local sha="${GITHUB_SHA:-}"

    if [[ -z "$ref" ]]; then
        log_error "GITHUB_REF not set - are you running in GitHub Actions?"
        return 1
    fi

    log_info "Event-driven sync triggered"
    log_info "Ref: $ref"
    log_info "SHA: ${sha:0:12}"

    # Extract branch or tag name
    local ref_type ref_name
    if [[ "$ref" == refs/heads/* ]]; then
        ref_type="branch"
        ref_name="${ref#refs/heads/}"
    elif [[ "$ref" == refs/tags/* ]]; then
        ref_type="tag"
        ref_name="${ref#refs/tags/}"
    else
        log_warn "Unknown ref type: $ref"
        return 0
    fi

    log_info "Syncing $ref_type: $ref_name"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would push $ref to $MIRROR_REMOTE"
        return 0
    fi

    if git push "$MIRROR_REMOTE" "$ref:$ref" --force; then
        log_success "Synced $ref_type: $ref_name"
        return 0
    else
        log_error "Failed to sync $ref_type: $ref_name"
        return 1
    fi
}

# Full mirror sync
full_sync() {
    log_info "Starting full mirror sync..."

    # Fetch latest from source
    log_info "Fetching from $SOURCE_REMOTE..."
    git fetch "$SOURCE_REMOTE" --prune --tags

    local exit_code=0

    sync_all_branches || exit_code=1
    sync_tags || exit_code=1

    return $exit_code
}

# Main function
main() {
    cd "$PROJECT_ROOT"

    log_info "Mirror sync utility"
    echo ""

    local mode="push"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mirror-url) MIRROR_URL="$2"; shift 2 ;;
            --source) SOURCE_REMOTE="$2"; shift 2 ;;
            --mirror) MIRROR_REMOTE="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            --full) mode="full"; shift ;;
            --push) mode="push"; shift ;;
            *) shift ;;
        esac
    done

    # Setup remote if URL provided
    if [[ -n "$MIRROR_URL" ]]; then
        setup_mirror_remote || return 1
    fi

    # Verify mirror remote exists
    if ! git remote get-url "$MIRROR_REMOTE" &>/dev/null; then
        log_error "Mirror remote '$MIRROR_REMOTE' not configured. Set MIRROR_URL or add remote manually."
        return 1
    fi

    local exit_code=0

    case "$mode" in
        push)
            sync_on_push || exit_code=1
            ;;
        full)
            full_sync || exit_code=1
            ;;
    esac

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Mirror sync completed successfully!"
    else
        log_error "Mirror sync completed with errors"
    fi

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
