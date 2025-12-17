;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — universal-project-manager

(ecosystem
  (version "1.0.0")
  (name "universal-project-manager")
  (type "project")
  (purpose "Language-agnostic CI/CD infrastructure and project management tooling")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "A universal CI/CD solution providing auto-detection, platform-agnostic scripts, and repository mirroring")
  (what-this-is-not "- NOT exempt from RSR compliance\n- NOT a replacement for platform-specific CI/CD systems"))
