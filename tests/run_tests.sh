#!/usr/bin/env bash
# Test runner script for the Universal Project Manager CI scripts
# Runs BATS tests if available, otherwise skips with a warning

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Install BATS if not available
install_bats() {
    log_info "Installing BATS..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y bats
    elif command -v brew &>/dev/null; then
        brew install bats-core
    elif command -v npm &>/dev/null; then
        npm install -g bats
    else
        log_error "Cannot install BATS automatically. Please install it manually."
        log_info "Visit: https://github.com/bats-core/bats-core"
        return 1
    fi
}

# Run BATS tests
run_bats_tests() {
    log_info "Running BATS tests..."

    local test_files
    test_files=$(find "$SCRIPT_DIR" -name "*.bats" 2>/dev/null || true)

    if [[ -z "$test_files" ]]; then
        log_warn "No BATS test files found"
        return 0
    fi

    if command -v bats &>/dev/null; then
        bats "$SCRIPT_DIR"/*.bats
    else
        log_warn "BATS not installed. Skipping shell tests."
        log_info "Install with: npm install -g bats"
        return 0
    fi
}

# Run shellcheck on all scripts
run_shellcheck() {
    log_info "Running shellcheck on CI scripts..."

    if command -v shellcheck &>/dev/null; then
        local scripts
        scripts=$(find "$PROJECT_ROOT/ci-scripts" -name "*.sh" 2>/dev/null || true)

        if [[ -n "$scripts" ]]; then
            echo "$scripts" | xargs shellcheck
            log_success "shellcheck passed"
        fi
    else
        log_warn "shellcheck not installed. Skipping static analysis."
    fi
}

# Main function
main() {
    log_info "Starting test runner..."
    echo ""

    local exit_code=0

    # Run shellcheck
    run_shellcheck || exit_code=1

    echo ""

    # Run BATS tests
    run_bats_tests || exit_code=1

    echo ""

    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed!"
    else
        log_error "Some tests failed"
    fi

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
