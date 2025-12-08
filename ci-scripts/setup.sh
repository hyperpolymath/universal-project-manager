#!/usr/bin/env bash
# Universal Setup Script
# Installs dependencies based on detected project type
# Exit codes: 0 = success, 1 = error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Source detection script
source "$SCRIPT_DIR/detect.sh" 2>/dev/null || true

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

# Setup Node.js dependencies
setup_nodejs() {
    log_info "Setting up Node.js dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "pnpm-lock.yaml" ]]; then
        log_info "Using pnpm..."
        pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    elif [[ -f "yarn.lock" ]]; then
        log_info "Using yarn..."
        yarn install --frozen-lockfile 2>/dev/null || yarn install
    elif [[ -f "bun.lockb" ]]; then
        log_info "Using bun..."
        bun install --frozen-lockfile 2>/dev/null || bun install
    elif [[ -f "package-lock.json" ]]; then
        log_info "Using npm ci..."
        npm ci 2>/dev/null || npm install
    elif [[ -f "package.json" ]]; then
        log_info "Using npm install..."
        npm install
    fi

    log_success "Node.js dependencies installed"
}

# Setup Python dependencies
setup_python() {
    log_info "Setting up Python dependencies..."

    cd "$PROJECT_ROOT"

    # Create virtual environment if not exists
    if [[ ! -d ".venv" && ! -d "venv" ]]; then
        log_info "Creating virtual environment..."
        python3 -m venv .venv || python -m venv .venv
    fi

    # Activate virtual environment
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate 2>/dev/null || true
    elif [[ -d "venv" ]]; then
        source venv/bin/activate 2>/dev/null || true
    fi

    # Install dependencies
    if [[ -f "poetry.lock" ]]; then
        log_info "Using poetry..."
        poetry install --no-interaction
    elif [[ -f "Pipfile" ]]; then
        log_info "Using pipenv..."
        pipenv install --dev
    elif [[ -f "pyproject.toml" ]]; then
        log_info "Installing from pyproject.toml..."
        pip install -e ".[dev]" 2>/dev/null || pip install -e .
    elif [[ -f "requirements.txt" ]]; then
        log_info "Using pip..."
        pip install -r requirements.txt
        [[ -f "requirements-dev.txt" ]] && pip install -r requirements-dev.txt
    fi

    log_success "Python dependencies installed"
}

# Setup Ruby dependencies
setup_ruby() {
    log_info "Setting up Ruby dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "Gemfile" ]]; then
        log_info "Using bundler..."
        bundle install
    fi

    log_success "Ruby dependencies installed"
}

# Setup Go dependencies
setup_go() {
    log_info "Setting up Go dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "go.mod" ]]; then
        log_info "Downloading Go modules..."
        go mod download
        go mod verify
    fi

    log_success "Go dependencies installed"
}

# Setup Rust dependencies
setup_rust() {
    log_info "Setting up Rust dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "Cargo.toml" ]]; then
        log_info "Fetching Rust crates..."
        cargo fetch
    fi

    log_success "Rust dependencies installed"
}

# Setup Java/Maven dependencies
setup_java_maven() {
    log_info "Setting up Maven dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "pom.xml" ]]; then
        mvn dependency:resolve -q
    fi

    log_success "Maven dependencies installed"
}

# Setup Java/Gradle dependencies
setup_java_gradle() {
    log_info "Setting up Gradle dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
        if [[ -f "gradlew" ]]; then
            ./gradlew dependencies --quiet
        else
            gradle dependencies --quiet
        fi
    fi

    log_success "Gradle dependencies installed"
}

# Setup PHP dependencies
setup_php() {
    log_info "Setting up PHP dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f "composer.json" ]]; then
        composer install --no-interaction
    fi

    log_success "PHP dependencies installed"
}

# Setup .NET dependencies
setup_dotnet() {
    log_info "Setting up .NET dependencies..."

    cd "$PROJECT_ROOT"

    dotnet restore

    log_success ".NET dependencies installed"
}

# Main function
main() {
    log_info "Starting dependency setup in: $PROJECT_ROOT"

    # Run detection if not already done
    if [[ -z "${DETECTED_PACKAGE_MANAGERS:-}" ]]; then
        source "$SCRIPT_DIR/detect.sh"
        detect_languages
        detect_package_managers
    fi

    local setup_count=0

    # Setup based on detected package managers
    IFS=',' read -ra managers <<< "$DETECTED_PACKAGE_MANAGERS"

    for manager in "${managers[@]}"; do
        case "$manager" in
            npm|yarn|pnpm|bun)
                setup_nodejs
                ((setup_count++)) || true
                break  # Only need to run once for Node.js
                ;;
            pip|pipenv|poetry)
                setup_python
                ((setup_count++)) || true
                break  # Only need to run once for Python
                ;;
            bundler)
                setup_ruby
                ((setup_count++)) || true
                ;;
            go-modules)
                setup_go
                ((setup_count++)) || true
                ;;
            cargo)
                setup_rust
                ((setup_count++)) || true
                ;;
            maven)
                setup_java_maven
                ((setup_count++)) || true
                ;;
            gradle)
                setup_java_gradle
                ((setup_count++)) || true
                ;;
            composer)
                setup_php
                ((setup_count++)) || true
                ;;
            dotnet)
                setup_dotnet
                ((setup_count++)) || true
                ;;
        esac
    done

    if [[ $setup_count -eq 0 ]]; then
        log_warn "No recognized package managers found. Skipping dependency installation."
    fi

    echo ""
    log_success "Setup complete! ($setup_count package manager(s) configured)"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
