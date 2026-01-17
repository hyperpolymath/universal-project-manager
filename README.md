# Universal Project Manager

[![CI](https://github.com/hyperpolymath/Universal-Project-Manager/actions/workflows/ci.yml/badge.svg)](https://github.com/hyperpolymath/Universal-Project-Manager/actions/workflows/ci.yml)
[![CodeQL](https://github.com/hyperpolymath/Universal-Project-Manager/actions/workflows/codeql.yml/badge.svg)](https://github.com/hyperpolymath/Universal-Project-Manager/actions/workflows/codeql.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, language-agnostic CI/CD framework that automatically detects project configurations and provides unified scripts for building, testing, and deploying across multiple platforms.

## Features

- **Auto-Detection**: Automatically detects programming languages, package managers, test frameworks, and build systems
- **Multi-Language Support**: JavaScript/TypeScript, Python, Ruby, Go, Rust, Java/Kotlin, C/C++, C#, PHP, and more
- **Platform Agnostic**: Works with GitHub Actions and GitLab CI out of the box
- **Mirror Sync**: Event-driven repository mirroring between platforms
- **Unified Scripts**: Single set of scripts that work across all CI platforms

## Quick Start

### 1. Copy CI Scripts

Copy the `ci-scripts/` directory to your project:

```bash
cp -r ci-scripts/ /path/to/your/project/
chmod +x /path/to/your/project/ci-scripts/*.sh
```

### 2. Run Detection

```bash
./ci-scripts/detect.sh
```

Output:
```
[INFO] Detecting project configuration in: /your/project
[SUCCESS] Detection complete!

Languages detected: javascript,typescript
Primary language: javascript
Package managers: npm
Test frameworks: jest
Build systems: npm-scripts,webpack
```

### 3. Setup Dependencies

```bash
./ci-scripts/setup.sh
```

### 4. Run Tests

```bash
./ci-scripts/test.sh --coverage
```

### 5. Lint Code

```bash
./ci-scripts/lint.sh
# Or with auto-fix:
./ci-scripts/lint.sh --fix
```

### 6. Build

```bash
./ci-scripts/build.sh --release
```

## CI Scripts Reference

| Script | Description | Options |
|--------|-------------|---------|
| `detect.sh` | Detects project configuration | `json` - Output as JSON |
| `setup.sh` | Installs project dependencies | - |
| `test.sh` | Runs test suites | `--coverage`, `--verbose`, `--ci` |
| `lint.sh` | Runs code linters | `--fix`, `--verbose` |
| `build.sh` | Builds the project | `--release`, `--debug` |
| `sync-mirror.sh` | Syncs to mirror repository | `--mirror-url`, `--dry-run` |
| `verify-mirror.sh` | Verifies mirror sync | `--source`, `--mirror` |

## Supported Languages

| Language | Package Manager | Test Framework | Linter |
|----------|----------------|----------------|--------|
| JavaScript/TypeScript | npm, yarn, pnpm, bun | Jest, Mocha, Vitest, AVA | ESLint, Prettier |
| Python | pip, pipenv, poetry | pytest, unittest, tox | Ruff, Flake8, Black, mypy |
| Ruby | Bundler | RSpec, Minitest | RuboCop |
| Go | Go Modules | go test | golangci-lint, go vet |
| Rust | Cargo | cargo test | clippy, rustfmt |
| Java/Kotlin | Maven, Gradle | JUnit | Checkstyle, SpotBugs |
| C/C++ | CMake, Make | - | clang-format |
| C#/.NET | NuGet | xUnit, NUnit | dotnet format |
| PHP | Composer | PHPUnit | PHP-CS-Fixer, PHPStan |

## CI/CD Integration

### GitHub Actions

The included `.github/workflows/ci.yml` provides:

- Automatic language detection
- Matrix testing across OS and language versions
- Dependency caching
- Code coverage reporting
- Build artifact uploads
- Docker image builds
- Automatic releases on tags
- Event-driven mirror sync

### GitLab CI

The included `.gitlab-ci.yml` provides:

- Language-specific job templates
- Parallel test execution
- Coverage reporting
- Container Registry integration
- GitLab Pages deployment
- Release automation

## Repository Mirroring

### Setup (GitHub to GitLab)

1. Generate an SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "github-to-gitlab-mirror" -f gitlab_mirror_key
   ```

2. Add the public key to GitLab as a deploy key with write access

3. Add secrets to GitHub:
   - `GITLAB_SSH_PRIVATE_KEY`: Contents of `gitlab_mirror_key`
   - `GITLAB_MIRROR_URL`: `git@gitlab.com:your/repo.git`

4. Push to main/master to trigger sync

See [SECRETS.md](SECRETS.md) for detailed instructions.

## Project Structure

```
.
├── ci-scripts/
│   ├── detect.sh         # Project detection
│   ├── setup.sh          # Dependency setup
│   ├── test.sh           # Test runner
│   ├── lint.sh           # Linter runner
│   ├── build.sh          # Build script
│   ├── sync-mirror.sh    # Mirror sync
│   └── verify-mirror.sh  # Mirror verification
├── tests/
│   ├── test_detect.bats  # BATS tests
│   └── run_tests.sh      # Test runner
├── .github/
│   ├── workflows/
│   │   ├── ci.yml        # Main CI workflow
│   │   └── codeql.yml    # Security scanning
│   └── dependabot.yml    # Dependency updates
├── .gitlab-ci.yml        # GitLab CI config
├── TODO.md               # Project TODO list
├── SECRETS.md            # Secrets documentation
├── ROADMAP.adoc          # Project roadmap
└── README.md             # This file
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_ROOT` | Project root directory | Script's parent dir |
| `CI` | CI environment flag | `false` |
| `COVERAGE` | Enable coverage reporting | `false` |
| `VERBOSE` | Enable verbose output | `false` |
| `FIX` | Auto-fix lint issues | `false` |
| `BUILD_MODE` | Build mode (`release`/`debug`) | `release` |

### Future: Configuration File

Support for a `upm.yml` configuration file is planned:

```yaml
version: 1

project:
  name: my-project
  type: nodejs  # Override auto-detection

ci:
  test:
    coverage: true
    parallel: true
  lint:
    fix: false
```

## Security

- **CodeQL**: Automated security scanning
- **Dependabot**: Automated dependency updates
- **SAST**: Static Application Security Testing

See [SECURITY.md](SECURITY.md) for security policy.

## Contributing

Contributions are welcome! Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) first.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./tests/run_tests.sh`
5. Submit a pull request

## Roadmap

See [ROADMAP.adoc](ROADMAP.adoc) for the full roadmap.

### MVP v1.0 Goals

- [x] Auto-detection for 10+ languages
- [x] GitHub Actions workflow
- [x] GitLab CI configuration
- [x] Mirror sync support
- [ ] Configuration file support
- [ ] CLI wrapper tool

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the need for unified CI/CD across multiple platforms
- Thanks to all contributors and users

---

**Note**: This project is mirrored between:
- GitHub: https://github.com/hyperpolymath/Universal-Project-Manager
- GitLab: https://gitlab.com/overarch-underpin/managers/universal-project-manager
