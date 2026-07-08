Summary:

- Add a focused stats reset validation test for #1644.
- Generate before/reset/after stats dumps in a single gem5 invocation.
- Parse the generated `stats.txt` with the test-local parser from #3291.
- Check selected resettable stats while documenting intentionally excluded
  lifetime/constant/host-side stats.

Motivation:

- `m5.stats.reset()` should reset per-window statistics.
- Fixed reference stats files are avoided because the before/after dumps are
  generated and compared in the same test run.

Implementation:

- Adds `tests/gem5/stats/configs/stats_reset_check.py`.
- Uses `ScalarStatTester` without external binaries, downloads, or
  ISA-specific setup.
- Dumps stats after 10 ticks, calls `m5.stats.reset()`, runs 1 more tick, and
  dumps stats again.
- Adds `tests/gem5/stats/test_stats_reset.py` to verify:
  - `system.reset_scalar` resets from 42 to 0.
  - `simTicks` is lower after reset than before reset.
- Treats missing after-reset resettable stats as zero only for the checked
  resettable stats, matching omitted-zero text stats behavior.
- Excludes `finalTick`, `simFreq`, and host measurement stats from comparison.

Testing:

- `git diff --check origin/develop...HEAD`
- `pre-commit run --files $(git diff --name-only origin/develop...HEAD)`
- `./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
- `cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt`

Current stacked-branch maintenance recheck:

- 2026-07-08 07:27 UTC: rebased `stats-reset-validator` onto the latest
  #3291 parser branch commit `6e24b3b44a`.
- 2026-07-08 07:27 UTC: changed the reset validator to the smaller
  `NULL` target because the config uses only `ScalarStatTester` and has no
  ISA-specific setup.
- 2026-07-08 07:27 UTC: PR2-only stack is now `0 1` against
  `stats-txt-parser-pyunit`.
- 2026-07-08 07:27 UTC: current PR2 candidate commit is
  `595c27591b tests: add stats reset validation`.
- 2026-07-08 07:27 UTC: `git diff --check stats-txt-parser-pyunit...HEAD`
  passed.
- 2026-07-08 07:27 UTC:
  `pre-commit run --files tests/gem5/stats/configs/stats_reset_check.py tests/gem5/stats/test_stats_reset.py`
  passed.
- 2026-07-08 07:27 UTC:
  `python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v`
  passed, 10 tests.
- 2026-07-08 07:27 UTC:
  `./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
  passed, 10 tests.
- 2026-07-08 07:27 UTC:
  `cd tests && ./main.py list -q --suites | grep -i stats-reset` listed
  `SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt`.
- 2026-07-08 07:27 UTC:
  `cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt`
  passed twice, 2 tests per run.

Local build note:

- `scons build/ALL/gem5.opt -j4` failed at link in this container because the
  local protobuf/protoc/header/library setup is inconsistent and produced
  protobuf/absl undefined references.
- `PROTOC=/bin/false scons build/NULL/gem5.opt -j4` with `USE_TEST_OBJECTS=y`
  passed and produced a working `build/NULL/gem5.opt` with `HAVE_PROTOBUF=0`.

Historical validation before the local `gem5.opt` environment broke:

- 2026-07-07 08:34 UTC: parser pyunit runner passed 10 tests under
  `gem5.opt`.
- 2026-07-07 08:34 UTC: reset test UID passed 2 tests in 0.62 seconds.
- 2026-07-07 07:48 UTC: intentionally changed `AFTER_RESET_TICKS` to 20 and
  confirmed the verifier failed with an actionable `simTicks` before/after
  message, then reverted to 1 and confirmed the suite passed again.

Compatibility:

- Does not change simulator behavior.
- Does not change stats output format.
- Does not add external dependencies or downloaded resources.

Follow-up:

- Extend the checked stat set only after maintainer feedback.
- Add broader workloads/configurations only if maintainers want more coverage.
- Before opening PR2, rerun the execution tests with a working
  upstream-base `build/NULL/gem5.opt`.
