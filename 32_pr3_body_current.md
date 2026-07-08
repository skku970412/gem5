Summary:

- Document the stats reset validation workflow in `tests/gem5/stats/README.md`.
- Explain why the validator generates before/reset/after dumps in one gem5
  invocation.
- Document why fixed reference stats files are avoided.
- Describe resettable stats, intentionally excluded lifetime/constant/host-side
  stats, omitted-zero behavior, and failure-message expectations.

Testing:

- `git diff --check origin/develop...HEAD`
- `pre-commit run --files tests/gem5/stats/README.md`
- `cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt`

Current stacked-branch maintenance recheck:

- 2026-07-08 07:27 UTC: rebased `stats-reset-validation-docs` onto the latest
  `stats-reset-validator` commit `33d79e2c2e`.
- 2026-07-08 07:27 UTC: PR3-only stack is now `0 1` against
  `stats-reset-validator`.
- 2026-07-08 07:27 UTC: current PR3 candidate commit is
  `d176af0239 tests: document stats reset validation`.
- 2026-07-08 07:27 UTC:
  `git diff --check stats-reset-validator...stats-reset-validation-docs`
  passed.
- 2026-07-08 07:27 UTC:
  `pre-commit run --files tests/gem5/stats/README.md` passed.
- 2026-07-08 07:27 UTC:
  `cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt`
  passed twice, 2 tests per run.

Local build note:

- `scons build/ALL/gem5.opt -j4` failed at link in this container due local
  protobuf/protoc/header/library mismatch and protobuf/absl undefined
  references.
- PR2 execution was verified with a working `build/NULL/gem5.opt` built with
  `PROTOC=/bin/false`, `USE_TEST_OBJECTS=y`, and `HAVE_PROTOBUF=0`.

Compatibility:

- Documentation only.
- Does not change simulator behavior.
- Does not change stats output format.

Follow-up:

- Update the docs if maintainers request broader reset coverage or additional
  allowlisted stat categories.
