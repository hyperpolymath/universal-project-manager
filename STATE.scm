;;; STATE.scm - Universal Project Manager State Document
;;; Format: Guile Scheme S-expressions
;;; Reference: https://github.com/hyperpolymath/state.scm

;; =============================================================================
;; METADATA
;; =============================================================================

(metadata
  (version "1.0")
  (project "Universal-Project-Manager")
  (created-at "2025-12-08T00:00:00Z")
  (updated-at "2025-12-08T00:00:00Z")
  (state-format-version "1.0"))

;; =============================================================================
;; CURRENT POSITION
;; =============================================================================

(current-position
  (phase "foundation")
  (phase-completion-percentage 80)
  (overall-mvp-completion 45)
  (status "in-progress")

  (summary
    "Core CI/CD infrastructure is solid with ~2,300 lines of production Bash code.
     Language detection supports 10+ languages. GitHub Actions and GitLab CI/CD
     pipelines are operational. BATS test suite exists but coverage is limited.
     Documentation framework established but needs completion. Pre-MVP state
     with no version tags yet.")

  (completed-items
    '("Core CI scripts (detect, setup, test, lint, build, mirror, verify)"
      "GitHub Actions workflow with 7 jobs"
      "GitLab CI/CD with language-specific jobs"
      "BATS test suite for detect.sh (17 test cases)"
      "Dependabot for 12 package ecosystems"
      "CodeQL security scanning"
      "Repository mirroring infrastructure (GitHub -> GitLab)"
      "README with quick start guide"
      "ROADMAP.adoc with phased strategy"
      "Issue templates (bug, feature, custom)"
      "MIT License and Code of Conduct"))

  (in-progress-items
    '("Documentation finalization"
      "CI checks stabilization"
      "Test coverage expansion"))

  (not-started-items
    '("Configuration file support (upm.yml)"
      "CLI wrapper tool"
      "Wiki mirroring"
      "Deployment scripts")))

;; =============================================================================
;; ROUTE TO MVP v1.0
;; =============================================================================

(mvp-roadmap
  (target-version "1.0.0")
  (phases

    ;; Phase 1: Foundation (Current)
    ((name "Phase 1: Foundation")
     (status "in-progress")
     (completion-percentage 80)
     (tasks
       '(("Establish CI/CD infrastructure" completed)
         ("Create platform-agnostic scripts" completed)
         ("Set up dual-platform CI" completed)
         ("Complete documentation" in-progress)
         ("Pass all CI checks" in-progress))))

    ;; Phase 2: Testing & Validation
    ((name "Phase 2: Testing & Validation")
     (status "pending")
     (completion-percentage 10)
     (tasks
       '(("Achieve 80%+ test coverage for CI scripts" pending)
         ("BATS tests for setup.sh" pending)
         ("BATS tests for lint.sh" pending)
         ("BATS tests for build.sh" pending)
         ("BATS tests for test.sh" pending)
         ("BATS tests for sync-mirror.sh" pending)
         ("BATS tests for verify-mirror.sh" pending)
         ("Integration testing with real-world repos" pending)
         ("User acceptance testing (3-5 beta testers)" pending))))

    ;; Phase 3: Feature Completion
    ((name "Phase 3: Feature Completion")
     (status "pending")
     (completion-percentage 0)
     (tasks
       '(("Configuration file support (upm.yml)" pending)
         ("Wiki mirroring between platforms" pending)
         ("Deployment scripts" pending)
         ("CLI wrapper tool" pending))))

    ;; Phase 4: MVP Release
    ((name "Phase 4: MVP v1.0 Release")
     (status "pending")
     (completion-percentage 0)
     (tasks
       '(("All Phase 1-3 features complete" pending)
         ("Full documentation review" pending)
         ("Security audit passed" pending)
         ("Performance benchmarks" pending)
         ("Release notes and changelog" pending)
         ("Version tag v1.0.0" pending))))))

;; =============================================================================
;; ISSUES & BLOCKERS
;; =============================================================================

(issues

  ;; Critical (P0)
  (critical
    '(("Missing test coverage"
       "Only detect.sh has tests. setup.sh, lint.sh, build.sh, test.sh,
        sync-mirror.sh, and verify-mirror.sh have zero unit tests.
        Cannot confidently release MVP without 80%+ coverage."
       (affected-files "ci-scripts/setup.sh" "ci-scripts/lint.sh"
                       "ci-scripts/build.sh" "ci-scripts/test.sh"
                       "ci-scripts/sync-mirror.sh" "ci-scripts/verify-mirror.sh"))

      ("CI checks not fully passing"
       "Need to verify all CI jobs pass consistently before MVP.
        Flaky tests or configuration issues could block release."
       (affected-files ".github/workflows/ci.yml" ".gitlab-ci.yml"))))

  ;; High Priority (P1)
  (high
    '(("No configuration file support"
       "Users cannot customize behavior without modifying scripts.
        upm.yml or similar needed for project-specific overrides."
       (planned-solution "Implement upm.yml parser in detect.sh"))

      ("Security audit incomplete"
       "Input validation in CI scripts needs review. SSH key handling
        and container security best practices not documented."
       (affected-files "ci-scripts/*.sh" "SECRETS.md"))

      ("Shellcheck compliance gaps"
       "Not all scripts pass shellcheck with zero warnings.
        Technical debt that should be addressed before v1.0."
       (affected-files "ci-scripts/*.sh"))))

  ;; Medium Priority (P2)
  (medium
    '(("Code duplication"
       "Common utility functions duplicated across scripts.
        Should extract to shared library (ci-scripts/lib/common.sh)."
       (estimated-impact "maintainability"))

      ("Limited error handling"
       "Some edge cases not gracefully handled (empty repos,
        corrupted config files, network failures)."
       (estimated-impact "reliability"))

      ("Logging inconsistency"
       "Output formatting varies between scripts. Need unified
        logging with verbosity levels."
       (estimated-impact "user-experience"))))

  ;; Low Priority (P3)
  (low
    '(("No performance benchmarks"
       "Unknown how detection/setup scales with large monorepos."
       (deferred-to "post-mvp"))

      ("Limited Windows support"
       "Scripts assume Unix environment. Git Bash compatibility
        not tested."
       (deferred-to "post-mvp")))))

;; =============================================================================
;; QUESTIONS FOR STAKEHOLDER
;; =============================================================================

(questions

  ;; Architecture Questions
  (architecture
    '(("Configuration file format preference"
       "For upm.yml - should we support YAML only, or also TOML/JSON?
        YAML is most common in CI/CD but TOML is gaining traction.")

      ("Shared library extraction"
       "Should common functions be extracted to ci-scripts/lib/common.sh
        now, or defer to post-MVP to avoid scope creep?")

      ("CLI tool language choice"
       "For the CLI wrapper - Bash script, or compiled binary (Go/Rust)?
        Bash is simpler but binary offers better UX and distribution.")))

  ;; Scope Questions
  (scope
    '(("MVP scope confirmation"
       "Is the current Phase 1-4 plan the right scope for v1.0?
        Should any features be added or deferred?")

      ("Beta tester recruitment"
       "Phase 2 calls for 3-5 beta testers. Do you have candidates
        in mind, or should this be an open call?")

      ("Wiki mirroring priority"
       "Wiki mirroring is in Phase 3. Is this essential for MVP
        or can it be deferred to v1.1?")))

  ;; Process Questions
  (process
    '(("Release cadence"
       "After v1.0, what release cadence is preferred?
        Semantic versioning assumed - major.minor.patch.")

      ("Branch protection"
       "Should branch protection rules be configured on main
        before MVP? Require PR reviews, passing CI, etc.")

      ("Contributor guidelines"
       "CONTRIBUTING.md does not exist. Should this be added
        before v1.0 to encourage community participation?"))))

;; =============================================================================
;; LONG-TERM ROADMAP (Post-MVP)
;; =============================================================================

(long-term-roadmap

  ;; v1.1 - Extended Platform Support
  ((version "1.1")
   (theme "Platform Expansion")
   (features
     '("Bitbucket Pipelines support"
       "Azure DevOps Pipelines support"
       "CircleCI configuration generation"
       "Jenkins pipeline support"
       "Wiki mirroring (if deferred from MVP)")))

  ;; v1.2 - Advanced Features
  ((version "1.2")
   (theme "Power User Features")
   (features
     '("Monorepo support (detect multiple projects)"
       "Custom language plugin system"
       "Parallel test execution"
       "Incremental builds"
       "Cache optimization strategies")))

  ;; v1.3 - Developer Experience
  ((version "1.3")
   (theme "Developer Experience")
   (features
     '("CLI tool with interactive mode"
       "IDE extensions (VS Code, JetBrains)"
       "Local CI simulation (run pipelines locally)"
       "Configuration wizard"
       "Migration tool from other CI systems")))

  ;; v2.0 - Enterprise & Scale
  ((version "2.0")
   (theme "Enterprise Ready")
   (features
     '("Web dashboard for monitoring"
       "Analytics and build insights"
       "Private registry support"
       "Self-hosted runner integration"
       "Multi-tenant organization support"
       "RBAC and audit logging"
       "SLA compliance reporting")))

  ;; Vision
  (vision
    "Universal Project Manager aims to become the de-facto standard for
     CI/CD configuration, reducing setup time from hours to minutes for
     any project regardless of language or platform. Success metrics:
     - 1000+ repositories using UPM
     - Support for 20+ programming languages
     - Active community with external contributors
     - Recognition as a CNCF or similar foundation project"))

;; =============================================================================
;; CRITICAL NEXT ACTIONS
;; =============================================================================

(critical-next-actions

  ((priority 1)
   (action "Write BATS tests for setup.sh")
   (rationale "Second-most-used script after detect.sh, critical path for users")
   (estimated-effort "medium")
   (phase "Phase 2"))

  ((priority 2)
   (action "Write BATS tests for lint.sh")
   (rationale "Linting is first quality gate, must work reliably")
   (estimated-effort "medium")
   (phase "Phase 2"))

  ((priority 3)
   (action "Write BATS tests for test.sh")
   (rationale "Test runner is core functionality")
   (estimated-effort "medium")
   (phase "Phase 2"))

  ((priority 4)
   (action "Write BATS tests for build.sh")
   (rationale "Build failures are high-impact")
   (estimated-effort "medium")
   (phase "Phase 2"))

  ((priority 5)
   (action "Ensure all CI checks pass consistently")
   (rationale "Cannot release MVP with failing CI")
   (estimated-effort "small")
   (phase "Phase 1"))

  ((priority 6)
   (action "Complete SECRETS.md documentation")
   (rationale "Users need clear guidance on secret management")
   (estimated-effort "small")
   (phase "Phase 1"))

  ((priority 7)
   (action "Design and implement upm.yml schema")
   (rationale "Core feature for customization")
   (estimated-effort "large")
   (phase "Phase 3"))

  ((priority 8)
   (action "Security audit of input validation")
   (rationale "Prevent injection attacks in CI scripts")
   (estimated-effort "medium")
   (phase "Phase 4")))

;; =============================================================================
;; PROJECT CATALOG
;; =============================================================================

(projects
  ((name "Universal-Project-Manager")
   (repository "https://github.com/hyperpolymath/Universal-Project-Manager")
   (mirror "https://gitlab.com/overarch-underpin/managers/universal-project-manager")
   (status "in-progress")
   (completion-percentage 45)
   (category "devops-tooling")
   (tech-stack '(bash github-actions gitlab-ci bats docker))
   (supported-languages '(javascript typescript python ruby go rust java
                          kotlin c cpp csharp php swift shell))
   (lines-of-code 2298)
   (test-coverage-percentage 15)
   (target-test-coverage 80)
   (dependencies '())
   (blockers '("missing-test-coverage" "ci-checks-unstable"))
   (next-actions '("write-setup-tests" "write-lint-tests" "fix-ci"))))

;; =============================================================================
;; HISTORY (Completion Snapshots)
;; =============================================================================

(history
  ((timestamp "2025-12-08T00:00:00Z")
   (event "STATE.scm created")
   (mvp-completion 45)
   (phase "foundation")
   (notes "Initial state capture. Core infrastructure complete."))

  ((timestamp "2025-12-07T00:00:00Z")
   (event "Repository migration complete")
   (mvp-completion 40)
   (phase "foundation")
   (notes "CI/CD and testing migrated via PR #2.")))

;; =============================================================================
;; SESSION CONTEXT
;; =============================================================================

(session
  (branch "claude/create-state-scm-01GBmStc2qDBN2ycvncBxh6G")
  (task "Create STATE.scm document")
  (context "Establishing project state tracking for MVP planning"))

;;; End of STATE.scm
