#!/usr/bin/env bash
# Universal Linter
# Runs code quality checks based on detected languages and configuration
# Exit codes: 0 = all checks pass, 1 = lint errors found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Configuration
FIX="${FIX:-false}"
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

# Source detection script
source "$SCRIPT_DIR/detect.sh" 2>/dev/null || true

# Track lint results
LINTS_RUN=0
LINTS_PASSED=0
LINTS_FAILED=0

# Run ESLint for JavaScript/TypeScript
run_eslint() {
    log_info "Running ESLint..."
    cd "$PROJECT_ROOT"

    local eslint_cmd=""

    if [[ -f "node_modules/.bin/eslint" ]]; then
        eslint_cmd="npx eslint"
    elif command -v eslint &>/dev/null; then
        eslint_cmd="eslint"
    fi

    if [[ -n "$eslint_cmd" ]]; then
        ((LINTS_RUN++)) || true

        # Check for ESLint config
        local has_config=false
        for cfg in .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml .eslintrc.yaml eslint.config.js eslint.config.mjs; do
            [[ -f "$PROJECT_ROOT/$cfg" ]] && has_config=true && break
        done

        if [[ "$has_config" == "false" ]]; then
            log_warn "No ESLint config found, skipping"
            return 0
        fi

        local cmd="$eslint_cmd ."
        [[ "$FIX" == "true" ]] && cmd="$cmd --fix"

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "ESLint passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "ESLint found issues"
            return 1
        fi
    fi
}

# Run Prettier for formatting
run_prettier() {
    log_info "Running Prettier..."
    cd "$PROJECT_ROOT"

    local prettier_cmd=""

    if [[ -f "node_modules/.bin/prettier" ]]; then
        prettier_cmd="npx prettier"
    elif command -v prettier &>/dev/null; then
        prettier_cmd="prettier"
    fi

    if [[ -n "$prettier_cmd" ]]; then
        # Check for Prettier config
        local has_config=false
        for cfg in .prettierrc .prettierrc.js .prettierrc.json .prettierrc.yml prettier.config.js; do
            [[ -f "$PROJECT_ROOT/$cfg" ]] && has_config=true && break
        done

        if [[ "$has_config" == "false" ]]; then
            log_warn "No Prettier config found, skipping"
            return 0
        fi

        ((LINTS_RUN++)) || true

        local cmd="$prettier_cmd --check ."
        [[ "$FIX" == "true" ]] && cmd="$prettier_cmd --write ."

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "Prettier check passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "Prettier found formatting issues"
            return 1
        fi
    fi
}

# Run TypeScript compiler for type checking
run_tsc() {
    log_info "Running TypeScript type check..."
    cd "$PROJECT_ROOT"

    if [[ -f "tsconfig.json" ]]; then
        ((LINTS_RUN++)) || true

        log_info "Running: npx tsc --noEmit"
        if npx tsc --noEmit; then
            ((LINTS_PASSED++)) || true
            log_success "TypeScript type check passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "TypeScript type check failed"
            return 1
        fi
    fi
}

# Run Python linters
run_python_lint() {
    log_info "Running Python linters..."
    cd "$PROJECT_ROOT"

    # Activate virtual environment if exists
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate 2>/dev/null || true
    elif [[ -d "venv" ]]; then
        source venv/bin/activate 2>/dev/null || true
    fi

    # Ruff (fast Python linter)
    if command -v ruff &>/dev/null; then
        ((LINTS_RUN++)) || true

        local cmd="ruff check ."
        [[ "$FIX" == "true" ]] && cmd="ruff check --fix ."

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "Ruff passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "Ruff found issues"
        fi
    # Flake8
    elif command -v flake8 &>/dev/null; then
        ((LINTS_RUN++)) || true

        log_info "Running: flake8 ."
        if flake8 .; then
            ((LINTS_PASSED++)) || true
            log_success "Flake8 passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "Flake8 found issues"
        fi
    # Pylint
    elif command -v pylint &>/dev/null; then
        ((LINTS_RUN++)) || true

        log_info "Running: pylint **/*.py"
        if find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" | xargs pylint --exit-zero; then
            ((LINTS_PASSED++)) || true
            log_success "Pylint passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "Pylint found issues"
        fi
    fi

    # Black (formatter)
    if command -v black &>/dev/null; then
        ((LINTS_RUN++)) || true

        local cmd="black --check ."
        [[ "$FIX" == "true" ]] && cmd="black ."

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "Black check passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "Black found formatting issues"
        fi
    fi

    # mypy (type checker)
    if command -v mypy &>/dev/null && [[ -f "mypy.ini" || -f "pyproject.toml" ]]; then
        ((LINTS_RUN++)) || true

        log_info "Running: mypy ."
        if mypy .; then
            ((LINTS_PASSED++)) || true
            log_success "mypy type check passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "mypy found type issues"
        fi
    fi
}

# Run Ruby linters
run_ruby_lint() {
    log_info "Running Ruby linters..."
    cd "$PROJECT_ROOT"

    # RuboCop
    if [[ -f "Gemfile" ]] && grep -q "rubocop" Gemfile 2>/dev/null; then
        ((LINTS_RUN++)) || true

        local cmd="bundle exec rubocop"
        [[ "$FIX" == "true" ]] && cmd="$cmd -a"

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "RuboCop passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "RuboCop found issues"
            return 1
        fi
    fi
}

# Run Go linters
run_go_lint() {
    log_info "Running Go linters..."
    cd "$PROJECT_ROOT"

    # golangci-lint
    if command -v golangci-lint &>/dev/null; then
        ((LINTS_RUN++)) || true

        local cmd="golangci-lint run"
        [[ "$FIX" == "true" ]] && cmd="$cmd --fix"

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "golangci-lint passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "golangci-lint found issues"
            return 1
        fi
    # go vet (built-in)
    elif command -v go &>/dev/null; then
        ((LINTS_RUN++)) || true

        log_info "Running: go vet ./..."
        if go vet ./...; then
            ((LINTS_PASSED++)) || true
            log_success "go vet passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "go vet found issues"
            return 1
        fi
    fi

    # gofmt check
    if command -v gofmt &>/dev/null; then
        ((LINTS_RUN++)) || true

        log_info "Checking gofmt..."
        local unformatted
        unformatted=$(gofmt -l . 2>/dev/null | grep -v vendor || true)

        if [[ -z "$unformatted" ]]; then
            ((LINTS_PASSED++)) || true
            log_success "gofmt check passed"
        else
            if [[ "$FIX" == "true" ]]; then
                gofmt -w .
                ((LINTS_PASSED++)) || true
                log_success "gofmt applied fixes"
            else
                ((LINTS_FAILED++)) || true
                log_error "gofmt found unformatted files:"
                echo "$unformatted"
                return 1
            fi
        fi
    fi
}

# Run Rust linters
run_rust_lint() {
    log_info "Running Rust linters..."
    cd "$PROJECT_ROOT"

    if [[ -f "Cargo.toml" ]]; then
        # cargo fmt check
        ((LINTS_RUN++)) || true

        local cmd="cargo fmt --check"
        [[ "$FIX" == "true" ]] && cmd="cargo fmt"

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "cargo fmt check passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "cargo fmt found formatting issues"
        fi

        # cargo clippy
        ((LINTS_RUN++)) || true

        log_info "Running: cargo clippy"
        if cargo clippy -- -D warnings; then
            ((LINTS_PASSED++)) || true
            log_success "cargo clippy passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "cargo clippy found issues"
            return 1
        fi
    fi
}

# Run shell script linters
run_shell_lint() {
    log_info "Running shell script linters..."
    cd "$PROJECT_ROOT"

    # shellcheck
    if command -v shellcheck &>/dev/null; then
        local shell_files
        shell_files=$(find . -name "*.sh" -o -name "*.bash" 2>/dev/null | grep -v node_modules | grep -v vendor || true)

        if [[ -n "$shell_files" ]]; then
            ((LINTS_RUN++)) || true

            log_info "Running: shellcheck on shell scripts"
            if echo "$shell_files" | xargs shellcheck; then
                ((LINTS_PASSED++)) || true
                log_success "shellcheck passed"
            else
                ((LINTS_FAILED++)) || true
                log_error "shellcheck found issues"
                return 1
            fi
        fi
    fi
}

# Run PHP linters
run_php_lint() {
    log_info "Running PHP linters..."
    cd "$PROJECT_ROOT"

    # PHP-CS-Fixer
    if [[ -f "vendor/bin/php-cs-fixer" ]]; then
        ((LINTS_RUN++)) || true

        local cmd="./vendor/bin/php-cs-fixer fix --dry-run --diff"
        [[ "$FIX" == "true" ]] && cmd="./vendor/bin/php-cs-fixer fix"

        log_info "Running: $cmd"
        if eval "$cmd"; then
            ((LINTS_PASSED++)) || true
            log_success "PHP-CS-Fixer passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "PHP-CS-Fixer found issues"
            return 1
        fi
    # PHPStan
    elif [[ -f "vendor/bin/phpstan" ]]; then
        ((LINTS_RUN++)) || true

        log_info "Running: ./vendor/bin/phpstan analyse"
        if ./vendor/bin/phpstan analyse; then
            ((LINTS_PASSED++)) || true
            log_success "PHPStan passed"
        else
            ((LINTS_FAILED++)) || true
            log_error "PHPStan found issues"
            return 1
        fi
    fi
}

# Print lint summary
print_summary() {
    echo ""
    echo "========================================"
    echo "           LINT SUMMARY"
    echo "========================================"
    echo "Linters run:    $LINTS_RUN"
    echo "Linters passed: $LINTS_PASSED"
    echo "Linters failed: $LINTS_FAILED"
    echo "========================================"

    if [[ $LINTS_FAILED -gt 0 ]]; then
        log_error "Some linters found issues!"
        return 1
    elif [[ $LINTS_RUN -eq 0 ]]; then
        log_warn "No linters were run"
        return 0
    else
        log_success "All linters passed!"
        return 0
    fi
}

# Main function
main() {
    log_info "Starting linter in: $PROJECT_ROOT"
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix) FIX="true"; shift ;;
            --verbose|-v) VERBOSE="true"; shift ;;
            *) shift ;;
        esac
    done

    # Run detection if not already done
    if [[ -z "${DETECTED_LANGUAGES:-}" ]]; then
        source "$SCRIPT_DIR/detect.sh"
        detect_languages
        detect_package_managers
    fi

    local exit_code=0

    # Run linters based on detected languages
    IFS=',' read -ra languages <<< "${DETECTED_LANGUAGES:-}"

    for lang in "${languages[@]}"; do
        case "$lang" in
            javascript|typescript)
                run_eslint || exit_code=1
                run_prettier || exit_code=1
                [[ "$lang" == "typescript" ]] && (run_tsc || exit_code=1)
                ;;
            python)
                run_python_lint || exit_code=1
                ;;
            ruby)
                run_ruby_lint || exit_code=1
                ;;
            go)
                run_go_lint || exit_code=1
                ;;
            rust)
                run_rust_lint || exit_code=1
                ;;
            php)
                run_php_lint || exit_code=1
                ;;
            shell)
                run_shell_lint || exit_code=1
                ;;
        esac
    done

    # Always run shell linter on ci-scripts
    run_shell_lint || exit_code=1

    print_summary || exit_code=$?

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
