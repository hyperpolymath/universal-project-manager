# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Universal-Project-Manager, please report it responsibly:

1. **DO NOT** open a public GitHub issue for security vulnerabilities
2. Email security concerns to: hyperpolymath@proton.me
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution Target**: Within 30 days (depending on severity)

### What to Expect

- Acknowledgment of your report
- Regular updates on the fix progress
- Credit in the security advisory (unless you prefer anonymity)
- Notification when the vulnerability is fixed

## Security Measures

This project implements the following security measures:

### Code Security
- **CodeQL SAST**: Automated security scanning on all commits
- **No weak cryptography**: MD5/SHA1 blocked for security purposes (SHA256+ required)
- **HTTPS only**: All URLs must use HTTPS
- **No hardcoded secrets**: Environment variables required for credentials

### CI/CD Security
- **SHA-pinned GitHub Actions**: All actions pinned to specific commits
- **Minimal permissions**: Workflows use least-privilege principle
- **Dependency scanning**: Automated via Dependabot

### Repository Security
- **Signed commits**: GPG signatures encouraged
- **Branch protection**: Main branch protected
- **Sigstore attestation**: SLSA provenance verification

## RSR Compliance

This project follows the Rhodium Standard Repository (RSR) security guidelines. See [RSR_COMPLIANCE.adoc](RSR_COMPLIANCE.adoc) for details.
