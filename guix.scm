;; Universal-Project-Manager - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public universal_project_manager
  (package
    (name "Universal-Project-Manager")
    (version "0.1.0")
    (source (local-file "." "Universal-Project-Manager-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (synopsis "Guix channel/infrastructure")
    (description "Guix channel/infrastructure - part of the RSR ecosystem.")
    (home-page "https://github.com/hyperpolymath/Universal-Project-Manager")
    (license license:agpl3+)))

;; Return package for guix shell
universal_project_manager
