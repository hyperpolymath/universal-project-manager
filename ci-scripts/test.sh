#!/usr/bin/env bash
# Universal Test Runner
# Runs tests based on detected frameworks and configuration
# Exit codes: 0 = all tests pass, 1 = test failures, 2 = no tests found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Configuration
COVERAGE="${COVERAGE:-false}"
VERBOSE="${VERBOSE:-false}"
CI="${CI:-false}"

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

# Track test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Run Node.js tests
run_nodejs_tests() {
    log_info "Running Node.js tests..."
    cd "$PROJECT_ROOT"

    local test_cmd=""
    local npm_cmd="npm"

    # Detect package manager
    [[ -f "pnpm-lock.yaml" ]] && npm_cmd="pnpm"
    [[ -f "yarn.lock" ]] && npm_cmd="yarn"
    [[ -f "bun.lockb" ]] && npm_cmd="bun"

    # Check package.json for test script
    if [[ -f "package.json" ]]; then
        if grep -q '"test"' package.json; then
            test_cmd="$npm_cmd test"
        fi
    fi

    # Try specific frameworks
    if [[ -z "$test_cmd" ]]; then
        if [[ -f "jest.config.js" || -f "jest.config.ts" || -f "jest.config.json" ]]; then
            test_cmd="npx jest"
        elif [[ -f "vitest.config.js" || -f "vitest.config.ts" ]]; then
            test_cmd="npx vitest run"
        elif [[ -d "node_modules/.bin" ]]; then
            [[ -f "node_modules/.bin/jest" ]] && test_cmd="npx jest"
            [[ -f "node_modules/.bin/mocha" ]] && test_cmd="npx mocha"
            [[ -f "node_modules/.bin/vitest" ]] && test_cmd="npx vitest run"
            [[ -f "node_modules/.bin/ava" ]] && test_cmd="npx ava"
        fi
    fi

    if [[ -n "$test_cmd" ]]; then
        ((TESTS_RUN++)) || true

        # Add coverage flag if requested
        if [[ "$COVERAGE" == "true" ]]; then
            [[ "$test_cmd" == *"jest"* ]] && test_cmd="$test_cmd --coverage"
            [[ "$test_cmd" == *"vitest"* ]] && test_cmd="$test_cmd --coverage"
        fi

        # Add CI flag if in CI environment
        if [[ "$CI" == "true" ]]; then
            [[ "$test_cmd" == *"jest"* ]] && test_cmd="$test_cmd --ci"
        fi

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "Node.js tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Node.js tests failed"
            return 1
        fi
    else
        log_warn "No Node.js test configuration found"
    fi
}

# Run Python tests
run_python_tests() {
    log_info "Running Python tests..."
    cd "$PROJECT_ROOT"

    # Activate virtual environment if exists
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate 2>/dev/null || true
    elif [[ -d "venv" ]]; then
        source venv/bin/activate 2>/dev/null || true
    fi

    local test_cmd=""

    # Check for pytest
    if command -v pytest &>/dev/null || [[ -f ".venv/bin/pytest" ]]; then
        test_cmd="pytest"
        [[ "$VERBOSE" == "true" ]] && test_cmd="$test_cmd -v"
        [[ "$COVERAGE" == "true" ]] && test_cmd="$test_cmd --cov=. --cov-report=xml"
    # Check for tox
    elif [[ -f "tox.ini" ]] && command -v tox &>/dev/null; then
        test_cmd="tox"
    # Fallback to unittest
    elif find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -q .; then
        test_cmd="python -m unittest discover"
    fi

    if [[ -n "$test_cmd" ]]; then
        ((TESTS_RUN++)) || true

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "Python tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Python tests failed"
            return 1
        fi
    else
        log_warn "No Python test configuration found"
    fi
}

# Run Ruby tests
run_ruby_tests() {
    log_info "Running Ruby tests..."
    cd "$PROJECT_ROOT"

    local test_cmd=""

    # Check for RSpec
    if [[ -d "spec" ]]; then
        test_cmd="bundle exec rspec"
    # Check for Minitest
    elif [[ -d "test" ]]; then
        test_cmd="bundle exec rake test"
    fi

    if [[ -n "$test_cmd" ]]; then
        ((TESTS_RUN++)) || true

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "Ruby tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Ruby tests failed"
            return 1
        fi
    else
        log_warn "No Ruby test configuration found"
    fi
}

# Run Go tests
run_go_tests() {
    log_info "Running Go tests..."
    cd "$PROJECT_ROOT"

    local test_cmd="go test ./..."
    [[ "$VERBOSE" == "true" ]] && test_cmd="$test_cmd -v"
    [[ "$COVERAGE" == "true" ]] && test_cmd="$test_cmd -coverprofile=coverage.out"

    if find . -name "*_test.go" 2>/dev/null | grep -q .; then
        ((TESTS_RUN++)) || true

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "Go tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Go tests failed"
            return 1
        fi
    else
        log_warn "No Go test files found"
    fi
}

# Run Rust tests
run_rust_tests() {
    log_info "Running Rust tests..."
    cd "$PROJECT_ROOT"

    if [[ -f "Cargo.toml" ]]; then
        ((TESTS_RUN++)) || true

        local test_cmd="cargo test"
        [[ "$VERBOSE" == "true" ]] && test_cmd="$test_cmd -- --nocapture"

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "Rust tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Rust tests failed"
            return 1
        fi
    else
        log_warn "No Cargo.toml found"
    fi
}

# Run Java/Maven tests
run_java_maven_tests() {
    log_info "Running Maven tests..."
    cd "$PROJECT_ROOT"

    if [[ -f "pom.xml" ]]; then
        ((TESTS_RUN++)) || true

        log_info "Running: mvn test"
        if mvn test -B; then
            ((TESTS_PASSED++)) || true
            log_success "Maven tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Maven tests failed"
            return 1
        fi
    fi
}

# Run Java/Gradle tests
run_java_gradle_tests() {
    log_info "Running Gradle tests..."
    cd "$PROJECT_ROOT"

    if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
        ((TESTS_RUN++)) || true

        local gradle_cmd="gradle"
        [[ -f "gradlew" ]] && gradle_cmd="./gradlew"

        log_info "Running: $gradle_cmd test"
        if $gradle_cmd test; then
            ((TESTS_PASSED++)) || true
            log_success "Gradle tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "Gradle tests failed"
            return 1
        fi
    fi
}

# Run PHP tests
run_php_tests() {
    log_info "Running PHP tests..."
    cd "$PROJECT_ROOT"

    if [[ -f "phpunit.xml" || -f "phpunit.xml.dist" ]]; then
        ((TESTS_RUN++)) || true

        local test_cmd="./vendor/bin/phpunit"
        [[ "$COVERAGE" == "true" ]] && test_cmd="$test_cmd --coverage-text"

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success "PHP tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error "PHP tests failed"
            return 1
        fi
    else
        log_warn "No PHPUnit configuration found"
    fi
}

# Run .NET tests
run_dotnet_tests() {
    log_info "Running .NET tests..."
    cd "$PROJECT_ROOT"

    if find . -name "*.csproj" 2>/dev/null | grep -q .; then
        ((TESTS_RUN++)) || true

        local test_cmd="dotnet test"
        [[ "$COVERAGE" == "true" ]] && test_cmd="$test_cmd --collect:'XPlat Code Coverage'"

        log_info "Running: $test_cmd"
        if eval "$test_cmd"; then
            ((TESTS_PASSED++)) || true
            log_success ".NET tests passed"
        else
            ((TESTS_FAILED++)) || true
            log_error ".NET tests failed"
            return 1
        fi
    fi
}

# Run shell script tests (BATS)
run_shell_tests() {
    log_info "Running shell tests..."
    cd "$PROJECT_ROOT"

    if [[ -d "test" ]] && find test -name "*.bats" 2>/dev/null | grep -q .; then
        if command -v bats &>/dev/null; then
            ((TESTS_RUN++)) || true

            log_info "Running: bats test/"
            if bats test/*.bats; then
                ((TESTS_PASSED++)) || true
                log_success "Shell tests passed"
            else
                ((TESTS_FAILED++)) || true
                log_error "Shell tests failed"
                return 1
            fi
        else
            log_warn "BATS not installed, skipping shell tests"
        fi
    fi
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "           TEST SUMMARY"
    echo "========================================"
    echo "Test suites run:    $TESTS_RUN"
    echo "Test suites passed: $TESTS_PASSED"
    echo "Test suites failed: $TESTS_FAILED"
    echo "========================================"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Some tests failed!"
        return 1
    elif [[ $TESTS_RUN -eq 0 ]]; then
        log_warn "No tests were run"
        return 2
    else
        log_success "All tests passed!"
        return 0
    fi
}

# Main function
main() {
    log_info "Starting test runner in: $PROJECT_ROOT"
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --coverage) COVERAGE="true"; shift ;;
            --verbose|-v) VERBOSE="true"; shift ;;
            --ci) CI="true"; shift ;;
            *) shift ;;
        esac
    done

    # Run detection if not already done
    if [[ -z "${DETECTED_LANGUAGES:-}" ]]; then
        source "$SCRIPT_DIR/detect.sh"
        detect_languages
        detect_package_managers
        detect_test_frameworks
    fi

    local exit_code=0

    # Run tests based on detected languages/frameworks
    IFS=',' read -ra languages <<< "${DETECTED_LANGUAGES:-}"

    for lang in "${languages[@]}"; do
        case "$lang" in
            javascript|typescript)
                run_nodejs_tests || exit_code=1
                ;;
            python)
                run_python_tests || exit_code=1
                ;;
            ruby)
                run_ruby_tests || exit_code=1
                ;;
            go)
                run_go_tests || exit_code=1
                ;;
            rust)
                run_rust_tests || exit_code=1
                ;;
            java|kotlin)
                if [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
                    run_java_maven_tests || exit_code=1
                elif [[ -f "$PROJECT_ROOT/build.gradle" || -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
                    run_java_gradle_tests || exit_code=1
                fi
                ;;
            php)
                run_php_tests || exit_code=1
                ;;
            csharp)
                run_dotnet_tests || exit_code=1
                ;;
            shell)
                run_shell_tests || exit_code=1
                ;;
        esac
    done

    print_summary || exit_code=$?

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
