# TEST-NEEDS.md — universal-project-manager

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| BATS shell tests | 1 | `tests/test_detect.bats` |
| Test runner scripts | 2 | `tests/run_tests.sh` + CI test script |
| Zig FFI tests | 1 | `ffi/zig/test/integration_test.zig` |
| Test infrastructure | Present | `tests/` directory |

## What's Covered

- [x] BATS framework for shell script testing
- [x] Project detection tests
- [x] Zig FFI integration tests
- [x] CI integration via test scripts

## Still Missing (for CRG B+)

- [ ] Multi-project manager compatibility tests
- [ ] Plugin integration tests
- [ ] Configuration edge case tests
- [ ] Performance benchmarks
- [ ] Cross-platform detection tests

## Run Tests

```bash
cd /var/mnt/eclipse/repos/universal-project-manager && bash tests/run_tests.sh
```
