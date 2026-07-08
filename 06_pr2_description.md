# PR2 reset validator description draft

Status: historical draft. Use `31_pr2_body_current.md` before opening PR2.

Do not open this PR until #3291 lands or maintainers explicitly accept a
stacked PR. Re-run the verification commands at that time, because the current
environment could not complete the latest `gem5.opt` parser pyunit runner after
the #3291 integer-preservation update.

## Intended title

```text
tests: validate m5.stats.reset output
```

## Intended scope

- Add a small stats reset validation test for #1644.
- Generate before/reset/after text stats in one gem5 invocation.
- Parse the generated `stats.txt` with the test-local parser from PR #3291.
- Check only selected resettable stats and document lifetime/constant stats
  that are intentionally not compared.

## Intended implementation

- Add `tests/gem5/stats/configs/stats_reset_check.py`.
- Use existing `ScalarStatTester` so the test does not need an external
  binary, workload download, or ISA-specific setup.
- Dump stats after 10 ticks, call `m5.stats.reset()`, run 1 more tick, and dump
  stats again.
- Add `tests/gem5/stats/test_stats_reset.py` with a small verifier that checks:
  - `system.reset_scalar` resets to zero.
  - `simTicks` is lower after reset than before reset.
- Exclude non-reset/lifetime stats such as `finalTick`, `simFreq`, and host
  measurement stats.
- Treat absent after-reset resettable stats as zero only for documented checked
  stats.

## Verification to rerun before opening

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

## Notes

- Older local runs passed the reset suite and parser pyunit before the latest
  #3291 review-response environment issue.
- Treat this file as context only. The current PR body source is
  `31_pr2_body_current.md`.
