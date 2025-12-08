#!/usr/bin/env bash
# Universal Build Script
# Builds the project based on detected configuration
# Exit codes: 0 = success, 1 = build error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Configuration
BUILD_MODE="${BUILD_MODE:-release}"  # release or debug
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

# Build Node.js project
build_nodejs() {
    log_info "Building Node.js project..."
    cd "$PROJECT_ROOT"

    local npm_cmd="npm"
    [[ -f "pnpm-lock.yaml" ]] && npm_cmd="pnpm"
    [[ -f "yarn.lock" ]] && npm_cmd="yarn"
    [[ -f "bun.lockb" ]] && npm_cmd="bun"

    # Check for build script
    if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
        log_info "Running: $npm_cmd run build"
        $npm_cmd run build
        log_success "Node.js build completed"
        return 0
    fi

    # TypeScript compilation
    if [[ -f "tsconfig.json" ]]; then
        log_info "Running: npx tsc"
        npx tsc
        log_success "TypeScript compilation completed"
        return 0
    fi

    log_warn "No build configuration found for Node.js"
    return 0
}

# Build Python project
build_python() {
    log_info "Building Python project..."
    cd "$PROJECT_ROOT"

    # Activate virtual environment if exists
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate 2>/dev/null || true
    elif [[ -d "venv" ]]; then
        source venv/bin/activate 2>/dev/null || true
    fi

    # Build wheel
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        log_info "Running: python -m build"
        python -m build 2>/dev/null || {
            log_info "Running: pip install build && python -m build"
            pip install build
            python -m build
        }
        log_success "Python build completed"
        return 0
    fi

    log_warn "No build configuration found for Python"
    return 0
}

# Build Go project
build_go() {
    log_info "Building Go project..."
    cd "$PROJECT_ROOT"

    if [[ -f "go.mod" ]]; then
        local build_flags=""
        [[ "$BUILD_MODE" == "release" ]] && build_flags="-ldflags='-s -w'"

        log_info "Running: go build $build_flags ./..."
        eval "go build $build_flags ./..."
        log_success "Go build completed"
        return 0
    fi

    log_warn "No Go module found"
    return 0
}

# Build Rust project
build_rust() {
    log_info "Building Rust project..."
    cd "$PROJECT_ROOT"

    if [[ -f "Cargo.toml" ]]; then
        local cmd="cargo build"
        [[ "$BUILD_MODE" == "release" ]] && cmd="cargo build --release"

        log_info "Running: $cmd"
        eval "$cmd"
        log_success "Rust build completed"
        return 0
    fi

    log_warn "No Cargo.toml found"
    return 0
}

# Build Java/Maven project
build_maven() {
    log_info "Building Maven project..."
    cd "$PROJECT_ROOT"

    if [[ -f "pom.xml" ]]; then
        log_info "Running: mvn package -DskipTests"
        mvn package -DskipTests -B
        log_success "Maven build completed"
        return 0
    fi

    return 0
}

# Build Java/Gradle project
build_gradle() {
    log_info "Building Gradle project..."
    cd "$PROJECT_ROOT"

    if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
        local gradle_cmd="gradle"
        [[ -f "gradlew" ]] && gradle_cmd="./gradlew"

        log_info "Running: $gradle_cmd build -x test"
        $gradle_cmd build -x test
        log_success "Gradle build completed"
        return 0
    fi

    return 0
}

# Build C/C++ project
build_cpp() {
    log_info "Building C/C++ project..."
    cd "$PROJECT_ROOT"

    # CMake
    if [[ -f "CMakeLists.txt" ]]; then
        mkdir -p build
        cd build
        log_info "Running: cmake .. && make"
        cmake ..
        make -j"$(nproc)"
        log_success "CMake build completed"
        return 0
    fi

    # Make
    if [[ -f "Makefile" ]]; then
        log_info "Running: make"
        make -j"$(nproc)"
        log_success "Make build completed"
        return 0
    fi

    log_warn "No build system found for C/C++"
    return 0
}

# Build .NET project
build_dotnet() {
    log_info "Building .NET project..."
    cd "$PROJECT_ROOT"

    if find . -name "*.csproj" -o -name "*.sln" 2>/dev/null | grep -q .; then
        local config="Release"
        [[ "$BUILD_MODE" == "debug" ]] && config="Debug"

        log_info "Running: dotnet build -c $config"
        dotnet build -c "$config"
        log_success ".NET build completed"
        return 0
    fi

    return 0
}

# Build Docker image
build_docker() {
    log_info "Building Docker image..."
    cd "$PROJECT_ROOT"

    if [[ -f "Dockerfile" ]]; then
        local image_name
        image_name=$(basename "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]')

        log_info "Running: docker build -t $image_name ."
        docker build -t "$image_name" .
        log_success "Docker build completed"
        return 0
    fi

    return 0
}

# Main function
main() {
    log_info "Starting build in: $PROJECT_ROOT"
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --release) BUILD_MODE="release"; shift ;;
            --debug) BUILD_MODE="debug"; shift ;;
            --verbose|-v) VERBOSE="true"; shift ;;
            *) shift ;;
        esac
    done

    log_info "Build mode: $BUILD_MODE"

    # Run detection if not already done
    if [[ -z "${DETECTED_LANGUAGES:-}" ]]; then
        source "$SCRIPT_DIR/detect.sh"
        detect_languages
        detect_package_managers
        detect_build_systems
    fi

    local builds_run=0
    local exit_code=0

    # Build based on detected languages/systems
    IFS=',' read -ra languages <<< "${DETECTED_LANGUAGES:-}"

    for lang in "${languages[@]}"; do
        case "$lang" in
            javascript|typescript)
                build_nodejs && ((builds_run++)) || exit_code=1
                ;;
            python)
                build_python && ((builds_run++)) || exit_code=1
                ;;
            go)
                build_go && ((builds_run++)) || exit_code=1
                ;;
            rust)
                build_rust && ((builds_run++)) || exit_code=1
                ;;
            java|kotlin)
                if [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
                    build_maven && ((builds_run++)) || exit_code=1
                elif [[ -f "$PROJECT_ROOT/build.gradle" || -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
                    build_gradle && ((builds_run++)) || exit_code=1
                fi
                ;;
            c-cpp)
                build_cpp && ((builds_run++)) || exit_code=1
                ;;
            csharp)
                build_dotnet && ((builds_run++)) || exit_code=1
                ;;
        esac
    done

    # Build Docker if Dockerfile exists
    if [[ -f "$PROJECT_ROOT/Dockerfile" ]]; then
        build_docker && ((builds_run++)) || exit_code=1
    fi

    echo ""
    if [[ $builds_run -eq 0 ]]; then
        log_warn "No build targets found"
    elif [[ $exit_code -eq 0 ]]; then
        log_success "All builds completed successfully!"
    else
        log_error "Some builds failed"
    fi

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
