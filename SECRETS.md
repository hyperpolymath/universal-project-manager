# Secrets Configuration Guide

This document lists all secrets required for the CI/CD pipelines to function properly.

## GitHub Repository Secrets

Configure these secrets in your GitHub repository:
**Settings** > **Secrets and variables** > **Actions** > **New repository secret**

### Required Secrets

| Secret Name | Description | Where to Get | Used By |
|-------------|-------------|--------------|---------|
| `GITLAB_SSH_PRIVATE_KEY` | SSH private key for GitLab push mirroring | Generate with `ssh-keygen -t ed25519 -C "github-mirror"` | `.github/workflows/ci.yml` (mirror job) |
| `GITLAB_MIRROR_URL` | GitLab repository URL for mirroring | `git@gitlab.com:overarch-underpin/managers/universal-project-manager.git` | `.github/workflows/ci.yml` (mirror job) |

### Optional Secrets

| Secret Name | Description | Where to Get | Used By |
|-------------|-------------|--------------|---------|
| `CODECOV_TOKEN` | Token for uploading coverage reports | [codecov.io](https://codecov.io) - Get from repo settings | `.github/workflows/ci.yml` (test job) |
| `SNYK_TOKEN` | Token for Snyk security scanning | [snyk.io](https://snyk.io) - Account settings | Security scanning workflows |
| `SONAR_TOKEN` | Token for SonarCloud analysis | [sonarcloud.io](https://sonarcloud.io) - Security tab | Code quality workflows |

### Built-in Secrets (No Configuration Needed)

| Secret Name | Description | Availability |
|-------------|-------------|--------------|
| `GITHUB_TOKEN` | Automatic GitHub token | Automatically available in all workflows |

---

## GitLab CI/CD Variables

Configure these variables in your GitLab project:
**Settings** > **CI/CD** > **Variables** > **Add variable**

### Required Variables

| Variable Name | Description | Where to Get | Protected | Masked |
|---------------|-------------|--------------|-----------|--------|
| `CI_REGISTRY_USER` | GitLab registry username | Your GitLab username | No | No |
| `CI_REGISTRY_PASSWORD` | GitLab registry password or token | GitLab Personal Access Token with `read_registry`, `write_registry` | Yes | Yes |

### Optional Variables

| Variable Name | Description | Where to Get | Protected | Masked |
|---------------|-------------|--------------|-----------|--------|
| `GITHUB_MIRROR_URL` | GitHub repository URL (if reverse mirroring) | `git@github.com:hyperpolymath/Universal-Project-Manager.git` | No | No |
| `GITHUB_SSH_PRIVATE_KEY` | SSH key for GitHub push | Generate with `ssh-keygen` | Yes | Yes |

### Predefined Variables (No Configuration Needed)

GitLab provides many predefined CI/CD variables automatically. Key ones include:

- `CI_COMMIT_REF_SLUG` - Slug of the branch or tag
- `CI_COMMIT_SHA` - Full commit SHA
- `CI_DEFAULT_BRANCH` - Default branch name
- `CI_PROJECT_PATH` - Project path with namespace
- `CI_REGISTRY` - GitLab Container Registry URL
- `CI_REGISTRY_IMAGE` - Registry image path

---

## Setup Instructions

### 1. Generate SSH Key for Mirroring

```bash
# Generate a new ED25519 SSH key pair
ssh-keygen -t ed25519 -C "github-to-gitlab-mirror" -f gitlab_mirror_key -N ""

# The private key (add to GitHub secrets as GITLAB_SSH_PRIVATE_KEY):
cat gitlab_mirror_key

# The public key (add to GitLab as a deploy key with write access):
cat gitlab_mirror_key.pub
```

### 2. Add Deploy Key to GitLab

1. Go to your GitLab project: **Settings** > **Repository** > **Deploy keys**
2. Click **Add deploy key**
3. Title: `GitHub Mirror`
4. Key: Paste the public key from `gitlab_mirror_key.pub`
5. **Enable** "Grant write permissions to this key"
6. Click **Add key**

### 3. Add SSH Key to GitHub

1. Go to your GitHub repository: **Settings** > **Secrets and variables** > **Actions**
2. Click **New repository secret**
3. Name: `GITLAB_SSH_PRIVATE_KEY`
4. Secret: Paste the entire contents of `gitlab_mirror_key` (including BEGIN/END lines)
5. Click **Add secret**

### 4. Add Mirror URL to GitHub

1. In the same GitHub Secrets page, click **New repository secret**
2. Name: `GITLAB_MIRROR_URL`
3. Secret: `git@gitlab.com:overarch-underpin/managers/universal-project-manager.git`
4. Click **Add secret**

### 5. Configure Codecov (Optional)

1. Go to [codecov.io](https://codecov.io) and sign in with GitHub
2. Add your repository
3. Copy the upload token from the repository settings
4. Add to GitHub Secrets as `CODECOV_TOKEN`

---

## Security Best Practices

### Do's

- Use **protected** variables for production secrets
- Use **masked** variables for sensitive values
- Rotate keys periodically (recommended: every 90 days)
- Use environment-specific secrets when possible
- Audit secret access regularly

### Don'ts

- Never commit secrets to the repository
- Never log secret values in CI output
- Never share secrets between unrelated projects
- Never use personal access tokens for CI (use deploy keys/tokens)
- Never disable masking for sensitive values

---

## Verification

### Test GitHub Mirror Setup

```bash
# From your local machine, verify the connection works
ssh -T git@gitlab.com -i ~/.ssh/gitlab_mirror_key
```

Expected output: `Welcome to GitLab, @username!`

### Test CI Pipeline

1. Push a small change to trigger the CI
2. Check the Actions tab for workflow runs
3. Verify the mirror job succeeds
4. Check GitLab to confirm the push arrived

---

## Troubleshooting

### Mirror Push Fails with "Permission denied"

- Verify the deploy key has **write permissions** on GitLab
- Check the SSH key format (should include BEGIN/END lines)
- Ensure the key isn't password-protected

### Codecov Upload Fails

- Verify the token is correct
- Check if the repository is properly activated on codecov.io
- Ensure coverage files are being generated

### GitLab Container Registry Auth Fails

- Use a Personal Access Token, not your password
- Token needs `read_registry` and `write_registry` scopes
- Variable should be **masked** and **protected**

---

## Contact

For issues with secret configuration:
- GitHub: Open an issue in this repository
- GitLab: Contact the project maintainers
