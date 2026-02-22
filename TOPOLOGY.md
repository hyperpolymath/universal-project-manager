<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Universal Project Manager (UPM) — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              OPERATOR / CI              │
                        │        (Justfile / Shell CLI)           │
                        └───────────────────┬─────────────────────┘
                                            │ Execute
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           DETECTION ENGINE              │
                        │    (detect.sh → Langs, PMs, Frameworks) │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ SETUP MANAGER         │  │ MIRROR SYNC                    │
                        │ - Dependency Install  │  │ - sync-mirror.sh               │
                        │ - detect.sh → setup   │  │ - verify-mirror.sh             │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │           ORCHESTRATION LAYER           │
                        │  ┌───────────┐  ┌───────────┐  ┌───────┐│
                        │  │ test.sh   │  │ lint.sh   │  │ build ││
                        │  │ (Runner)  │  │ (Checker) │  │ .sh   ││
                        │  └───────────┘  └───────────┘  └───────┘│
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           TARGET REPOSITORY             │
                        │      (14+ Langs, 15+ PMs, 20+ Tests)    │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  GitHub/GitLab CI     0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE CI SCRIPTS
  detect.sh (Auto-detection)        ██████████ 100%    14+ languages stable
  setup.sh (Dependencies)           ██████████ 100%    15+ package managers verified
  test.sh (Unified Runner)          ██████████ 100%    20+ frameworks active
  lint.sh (Quality Checker)         ██████████ 100%    Auto-fix logic stable
  build.sh (Orchestrator)           ██████████ 100%    15+ build systems verified

SYNC & MIRROR
  sync-mirror.sh                    ██████████ 100%    GH ↔ GL sync stable
  verify-mirror.sh                  ██████████ 100%    Sync verification active
  Secret Management                 ██████████ 100%    SSH key setup verified

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/test tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  BATS Test Suite                   ██████████ 100%    17 test cases passing

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ██████████ 100%    Phase 1 Foundation Complete
```

## Key Dependencies

```
detect.sh ──────► setup.sh ──────► test.sh / lint.sh ──────► build.sh
     │               │                   │                      │
     ▼               ▼                   ▼                      ▼
Langs/PMs ──────► Toolchain ───────► Coverage ───────────► Artifact
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
