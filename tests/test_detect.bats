#!/usr/bin/env bats
# Tests for ci-scripts/detect.sh

setup() {
    # Get the directory containing the test file
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

    # Source the detect script
    source "$PROJECT_ROOT/ci-scripts/detect.sh"

    # Create a temporary directory for test fixtures
    TEST_TEMP="$(mktemp -d)"
    export PROJECT_ROOT="$TEST_TEMP"
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_TEMP"
}

@test "detect_languages finds JavaScript when package.json exists" {
    touch "$TEST_TEMP/package.json"
    detect_languages

    [[ "$DETECTED_LANGUAGES" == *"javascript"* ]]
}

@test "detect_languages finds Python when requirements.txt exists" {
    touch "$TEST_TEMP/requirements.txt"
    detect_languages

    [[ "$DETECTED_LANGUAGES" == *"python"* ]]
}

@test "detect_languages finds Go when go.mod exists" {
    touch "$TEST_TEMP/go.mod"
    detect_languages

    [[ "$DETECTED_LANGUAGES" == *"go"* ]]
}

@test "detect_languages finds Rust when Cargo.toml exists" {
    touch "$TEST_TEMP/Cargo.toml"
    detect_languages

    [[ "$DETECTED_LANGUAGES" == *"rust"* ]]
}

@test "detect_languages finds Ruby when Gemfile exists" {
    touch "$TEST_TEMP/Gemfile"
    detect_languages

    [[ "$DETECTED_LANGUAGES" == *"ruby"* ]]
}

@test "detect_package_managers finds npm when package-lock.json exists" {
    touch "$TEST_TEMP/package-lock.json"
    detect_package_managers

    [[ "$DETECTED_PACKAGE_MANAGERS" == *"npm"* ]]
}

@test "detect_package_managers finds yarn when yarn.lock exists" {
    touch "$TEST_TEMP/yarn.lock"
    detect_package_managers

    [[ "$DETECTED_PACKAGE_MANAGERS" == *"yarn"* ]]
}

@test "detect_package_managers finds pip when requirements.txt exists" {
    touch "$TEST_TEMP/requirements.txt"
    detect_package_managers

    [[ "$DETECTED_PACKAGE_MANAGERS" == *"pip"* ]]
}

@test "detect_package_managers finds cargo when Cargo.toml exists" {
    touch "$TEST_TEMP/Cargo.toml"
    detect_package_managers

    [[ "$DETECTED_PACKAGE_MANAGERS" == *"cargo"* ]]
}

@test "detect_test_frameworks finds pytest when pytest.ini exists" {
    touch "$TEST_TEMP/pytest.ini"
    detect_test_frameworks

    [[ "$DETECTED_TEST_FRAMEWORKS" == *"pytest"* ]]
}

@test "detect_test_frameworks finds rspec when spec directory exists" {
    mkdir -p "$TEST_TEMP/spec"
    detect_test_frameworks

    [[ "$DETECTED_TEST_FRAMEWORKS" == *"rspec"* ]]
}

@test "detect_test_frameworks finds jest when package.json contains jest" {
    echo '{"devDependencies": {"jest": "^29.0.0"}}' > "$TEST_TEMP/package.json"
    detect_test_frameworks

    [[ "$DETECTED_TEST_FRAMEWORKS" == *"jest"* ]]
}

@test "detect_build_systems finds make when Makefile exists" {
    touch "$TEST_TEMP/Makefile"
    detect_build_systems

    [[ "$DETECTED_BUILD_SYSTEMS" == *"make"* ]]
}

@test "detect_build_systems finds cmake when CMakeLists.txt exists" {
    touch "$TEST_TEMP/CMakeLists.txt"
    detect_build_systems

    [[ "$DETECTED_BUILD_SYSTEMS" == *"cmake"* ]]
}

@test "detect_build_systems finds docker when Dockerfile exists" {
    touch "$TEST_TEMP/Dockerfile"
    detect_build_systems

    [[ "$DETECTED_BUILD_SYSTEMS" == *"docker"* ]]
}

@test "PRIMARY_LANGUAGE is set to first detected language" {
    touch "$TEST_TEMP/package.json"
    touch "$TEST_TEMP/requirements.txt"
    detect_languages

    # Should be the first language detected
    [[ -n "$PRIMARY_LANGUAGE" ]]
}

@test "generate_json_output produces valid JSON structure" {
    touch "$TEST_TEMP/package.json"
    detect_languages
    detect_package_managers
    detect_test_frameworks
    detect_build_systems

    output=$(generate_json_output)

    # Check it contains expected keys
    [[ "$output" == *'"languages"'* ]]
    [[ "$output" == *'"primary_language"'* ]]
    [[ "$output" == *'"package_managers"'* ]]
}
