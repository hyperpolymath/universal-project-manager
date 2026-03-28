; SPDX-License-Identifier: PMPL-1.0-or-later
;; guix.scm — GNU Guix package definition for universal-project-manager
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "universal-project-manager")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "universal-project-manager")
  (description "universal-project-manager — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/universal-project-manager")
  (license ((@@ (guix licenses) license) "PMPL-1.0-or-later"
             "https://github.com/hyperpolymath/palimpsest-license")))
