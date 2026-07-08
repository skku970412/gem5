# PR 2 opening packet: stats reset validator

Branch: `stats-reset-validator`

Dependency: PR #3291 must merge first.

Last refreshed: 2026-07-08 07:27 UTC

## Status

READY as a stacked follow-up branch, but not ready to open as a normal upstream
PR yet.

Do not open this against `gem5/develop` before #3291 merges. The diff would
include both the parser utility and the reset validator, which violates the
small/focused PR plan.

## Current Stack

```text
develop
  -> stats-txt-parser-pyunit       # PR #3291
    -> stats-reset-validator       # PR 2 candidate
      -> stats-reset-validation-docs
```

Current commits:

```text
stats-txt-parser-pyunit:     240b6f0961 tests: cover stats parser malformed boundaries
stats-reset-validator:       33d79e2c2e tests: add stats reset validation
stats-reset-validation-docs: d176af0239 tests: document stats reset validation
```

Current stack checks:

```sh
git rev-list --left-right --count stats-txt-parser-pyunit...stats-reset-validator
```

Result: `0 1`.

```sh
git merge-base --is-ancestor stats-txt-parser-pyunit stats-reset-validator
```

Result: passed.

## PR2-Only Diff

Diff base: `stats-txt-parser-pyunit...stats-reset-validator`

```text
tests/gem5/stats/configs/stats_reset_check.py |  50 ++++++++
tests/gem5/stats/test_stats_reset.py          | 162 ++++++++++++++++++++++++++
2 files changed, 212 insertions(+)
```

Files:

- `tests/gem5/stats/configs/stats_reset_check.py`
- `tests/gem5/stats/test_stats_reset.py`

## Latest Verification

Passed on 2026-07-08 after rebasing onto #3291 commit `240b6f0961`:

```sh
git diff --check stats-txt-parser-pyunit...HEAD
```

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/gem5/stats/configs/stats_reset_check.py \
  tests/gem5/stats/test_stats_reset.py
```

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
```

Result: parser pyunit passed 12 tests.

```sh
cd tests && ./main.py list -q --suites | grep -i stats
```

Result included:

```text
SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

The reset validator now targets `NULL` because the config uses only
`ScalarStatTester` and has no ISA-specific setup.

Passed on 2026-07-08 with local `build/NULL/gem5.opt` built using
`PROTOC=/bin/false` and `USE_TEST_OBJECTS=y`:

```sh
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

Results:

- pyunit passed 12 tests under `build/NULL/gem5.opt`.
- reset suite passed twice, 2 tests per run.

Default `ALL` build note:

- `scons build/ALL/gem5.opt -j4` failed at link in this container due local
  protobuf/protoc/header/library mismatch and protobuf/absl undefined
  references. This appears environment-specific, not caused by PR2.

Historical validation before the local `gem5.opt` environment broke:

- Reset suite passed twice with `--skip-build`.
- Parser pyunit passed under `gem5.opt`.
- Failure-mode check with `AFTER_RESET_TICKS = 20` failed as expected with an
  actionable `simTicks` before/after message, then passed after reverting to 1.

## Opening Steps After #3291 Merges

```sh
git fetch origin
git switch stats-reset-validator
git rebase origin/develop
git diff --name-only origin/develop...HEAD
```

Expected files:

```text
tests/gem5/stats/configs/stats_reset_check.py
tests/gem5/stats/test_stats_reset.py
```

Run:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

Push:

```sh
git push --force-with-lease fork stats-reset-validator
```

Open the PR against `gem5:develop`.

## Suggested PR Title

```text
tests: validate m5.stats.reset output
```

## Suggested PR Body

Use `31_pr2_body_current.md` and refresh its Testing section after rerunning
with a clean upstream-base `build/NULL/gem5.opt`.
