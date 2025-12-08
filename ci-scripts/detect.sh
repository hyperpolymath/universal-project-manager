#!/usr/bin/env bash
# Universal Project Detector
# Detects programming languages, package managers, and test frameworks
# Exit codes: 0 = success, 1 = error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Detection results (exported as environment variables)
export DETECTED_LANGUAGES=""
export DETECTED_PACKAGE_MANAGERS=""
export DETECTED_TEST_FRAMEWORKS=""
export DETECTED_BUILD_SYSTEMS=""
export PRIMARY_LANGUAGE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect languages based on file extensions and config files
detect_languages() {
    local languages=()

    # JavaScript/TypeScript
    if [[ -f "$PROJECT_ROOT/package.json" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -q .; then
        languages+=("javascript")
        if find "$PROJECT_ROOT" -maxdepth 3 -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -q .; then
            languages+=("typescript")
        fi
    fi

    # Python
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]] || \
       [[ -f "$PROJECT_ROOT/setup.py" ]] || \
       [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || \
       [[ -f "$PROJECT_ROOT/Pipfile" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.py" 2>/dev/null | grep -q .; then
        languages+=("python")
    fi

    # Ruby
    if [[ -f "$PROJECT_ROOT/Gemfile" ]] || \
       [[ -f "$PROJECT_ROOT/*.gemspec" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.rb" 2>/dev/null | grep -q .; then
        languages+=("ruby")
    fi

    # Go
    if [[ -f "$PROJECT_ROOT/go.mod" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.go" 2>/dev/null | grep -q .; then
        languages+=("go")
    fi

    # Rust
    if [[ -f "$PROJECT_ROOT/Cargo.toml" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.rs" 2>/dev/null | grep -q .; then
        languages+=("rust")
    fi

    # Java/Kotlin
    if [[ -f "$PROJECT_ROOT/pom.xml" ]] || \
       [[ -f "$PROJECT_ROOT/build.gradle" ]] || \
       [[ -f "$PROJECT_ROOT/build.gradle.kts" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.java" 2>/dev/null | grep -q .; then
        languages+=("java")
        if find "$PROJECT_ROOT" -maxdepth 3 -name "*.kt" 2>/dev/null | grep -q .; then
            languages+=("kotlin")
        fi
    fi

    # C/C++
    if [[ -f "$PROJECT_ROOT/CMakeLists.txt" ]] || \
       [[ -f "$PROJECT_ROOT/Makefile" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" 2>/dev/null | grep -q .; then
        languages+=("c-cpp")
    fi

    # C#/.NET
    if find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -o -name "*.sln" 2>/dev/null | grep -q .; then
        languages+=("csharp")
    fi

    # PHP
    if [[ -f "$PROJECT_ROOT/composer.json" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.php" 2>/dev/null | grep -q .; then
        languages+=("php")
    fi

    # Swift
    if [[ -f "$PROJECT_ROOT/Package.swift" ]] || \
       find "$PROJECT_ROOT" -maxdepth 3 -name "*.swift" 2>/dev/null | grep -q .; then
        languages+=("swift")
    fi

    # Shell scripts
    if find "$PROJECT_ROOT" -maxdepth 3 -name "*.sh" -o -name "*.bash" 2>/dev/null | grep -q .; then
        languages+=("shell")
    fi

    DETECTED_LANGUAGES=$(IFS=','; echo "${languages[*]}")

    # Set primary language (first detected)
    if [[ ${#languages[@]} -gt 0 ]]; then
        PRIMARY_LANGUAGE="${languages[0]}"
    fi
}

# Detect package managers
detect_package_managers() {
    local managers=()

    # Node.js ecosystem
    [[ -f "$PROJECT_ROOT/package-lock.json" ]] && managers+=("npm")
    [[ -f "$PROJECT_ROOT/yarn.lock" ]] && managers+=("yarn")
    [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]] && managers+=("pnpm")
    [[ -f "$PROJECT_ROOT/bun.lockb" ]] && managers+=("bun")

    # Python ecosystem
    [[ -f "$PROJECT_ROOT/requirements.txt" ]] && managers+=("pip")
    [[ -f "$PROJECT_ROOT/Pipfile" ]] && managers+=("pipenv")
    [[ -f "$PROJECT_ROOT/poetry.lock" ]] && managers+=("poetry")
    [[ -f "$PROJECT_ROOT/pyproject.toml" ]] && managers+=("pip") # could be poetry/pdm/etc

    # Ruby
    [[ -f "$PROJECT_ROOT/Gemfile" ]] && managers+=("bundler")

    # Go
    [[ -f "$PROJECT_ROOT/go.mod" ]] && managers+=("go-modules")

    # Rust
    [[ -f "$PROJECT_ROOT/Cargo.toml" ]] && managers+=("cargo")

    # Java/JVM
    [[ -f "$PROJECT_ROOT/pom.xml" ]] && managers+=("maven")
    [[ -f "$PROJECT_ROOT/build.gradle" || -f "$PROJECT_ROOT/build.gradle.kts" ]] && managers+=("gradle")

    # PHP
    [[ -f "$PROJECT_ROOT/composer.json" ]] && managers+=("composer")

    # .NET
    [[ -f "$PROJECT_ROOT/*.csproj" || -f "$PROJECT_ROOT/*.sln" ]] && managers+=("dotnet")

    DETECTED_PACKAGE_MANAGERS=$(IFS=','; echo "${managers[*]}")
}

# Detect test frameworks
detect_test_frameworks() {
    local frameworks=()

    # JavaScript/TypeScript
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        local pkg_content
        pkg_content=$(cat "$PROJECT_ROOT/package.json" 2>/dev/null || echo "{}")

        echo "$pkg_content" | grep -q '"jest"' && frameworks+=("jest")
        echo "$pkg_content" | grep -q '"mocha"' && frameworks+=("mocha")
        echo "$pkg_content" | grep -q '"vitest"' && frameworks+=("vitest")
        echo "$pkg_content" | grep -q '"ava"' && frameworks+=("ava")
        echo "$pkg_content" | grep -q '"tap"' && frameworks+=("tap")
        echo "$pkg_content" | grep -q '"@testing-library"' && frameworks+=("testing-library")
        echo "$pkg_content" | grep -q '"cypress"' && frameworks+=("cypress")
        echo "$pkg_content" | grep -q '"playwright"' && frameworks+=("playwright")
    fi

    # Python
    [[ -f "$PROJECT_ROOT/pytest.ini" || -f "$PROJECT_ROOT/pyproject.toml" ]] && frameworks+=("pytest")
    [[ -f "$PROJECT_ROOT/setup.cfg" ]] && grep -q "pytest" "$PROJECT_ROOT/setup.cfg" 2>/dev/null && frameworks+=("pytest")
    [[ -f "$PROJECT_ROOT/tox.ini" ]] && frameworks+=("tox")
    find "$PROJECT_ROOT" -maxdepth 3 -name "test_*.py" 2>/dev/null | grep -q . && frameworks+=("unittest")

    # Ruby
    [[ -d "$PROJECT_ROOT/spec" ]] && frameworks+=("rspec")
    [[ -d "$PROJECT_ROOT/test" ]] && frameworks+=("minitest")

    # Go
    find "$PROJECT_ROOT" -maxdepth 3 -name "*_test.go" 2>/dev/null | grep -q . && frameworks+=("go-test")

    # Rust
    [[ -f "$PROJECT_ROOT/Cargo.toml" ]] && frameworks+=("cargo-test")

    # Java
    [[ -d "$PROJECT_ROOT/src/test" ]] && frameworks+=("junit")

    DETECTED_TEST_FRAMEWORKS=$(IFS=','; echo "${frameworks[*]}")
}

# Detect build systems
detect_build_systems() {
    local systems=()

    [[ -f "$PROJECT_ROOT/Makefile" ]] && systems+=("make")
    [[ -f "$PROJECT_ROOT/CMakeLists.txt" ]] && systems+=("cmake")
    [[ -f "$PROJECT_ROOT/package.json" ]] && systems+=("npm-scripts")
    [[ -f "$PROJECT_ROOT/webpack.config.js" || -f "$PROJECT_ROOT/webpack.config.ts" ]] && systems+=("webpack")
    [[ -f "$PROJECT_ROOT/vite.config.js" || -f "$PROJECT_ROOT/vite.config.ts" ]] && systems+=("vite")
    [[ -f "$PROJECT_ROOT/rollup.config.js" ]] && systems+=("rollup")
    [[ -f "$PROJECT_ROOT/esbuild.config.js" ]] && systems+=("esbuild")
    [[ -f "$PROJECT_ROOT/tsconfig.json" ]] && systems+=("tsc")
    [[ -f "$PROJECT_ROOT/Dockerfile" ]] && systems+=("docker")
    [[ -f "$PROJECT_ROOT/docker-compose.yml" || -f "$PROJECT_ROOT/docker-compose.yaml" ]] && systems+=("docker-compose")

    DETECTED_BUILD_SYSTEMS=$(IFS=','; echo "${systems[*]}")
}

# Generate JSON output
generate_json_output() {
    cat <<EOF
{
  "languages": "$(echo "$DETECTED_LANGUAGES" | sed 's/,/", "/g')",
  "primary_language": "$PRIMARY_LANGUAGE",
  "package_managers": "$(echo "$DETECTED_PACKAGE_MANAGERS" | sed 's/,/", "/g')",
  "test_frameworks": "$(echo "$DETECTED_TEST_FRAMEWORKS" | sed 's/,/", "/g')",
  "build_systems": "$(echo "$DETECTED_BUILD_SYSTEMS" | sed 's/,/", "/g')"
}
EOF
}

# Main function
main() {
    local output_format="${1:-text}"

    log_info "Detecting project configuration in: $PROJECT_ROOT"

    detect_languages
    detect_package_managers
    detect_test_frameworks
    detect_build_systems

    if [[ "$output_format" == "json" ]]; then
        generate_json_output
    else
        echo ""
        log_success "Detection complete!"
        echo ""
        echo "Languages detected: ${DETECTED_LANGUAGES:-none}"
        echo "Primary language: ${PRIMARY_LANGUAGE:-unknown}"
        echo "Package managers: ${DETECTED_PACKAGE_MANAGERS:-none}"
        echo "Test frameworks: ${DETECTED_TEST_FRAMEWORKS:-none}"
        echo "Build systems: ${DETECTED_BUILD_SYSTEMS:-none}"
    fi

    # Export for use by other scripts
    export DETECTED_LANGUAGES
    export DETECTED_PACKAGE_MANAGERS
    export DETECTED_TEST_FRAMEWORKS
    export DETECTED_BUILD_SYSTEMS
    export PRIMARY_LANGUAGE
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
