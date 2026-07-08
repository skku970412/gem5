# PR 2 pre-PR gate: stats reset validator

Date checked: 2026-07-08 07:27 UTC

Branch: `stats-reset-validator`

Intended base after PR #3291 merges: `gem5/develop`

Current stack base: `stats-txt-parser-pyunit`

## Verdict

NOT READY to open as a normal upstream PR yet.

Reason: PR #3291 is still open. If `stats-reset-validator` is opened against
`gem5/develop` now, the diff includes both the parser utility and the reset
validator. Keep this branch staged until PR #3291 merges, then rebase onto
upstream `develop` and open only the reset validator.

## Technical readiness

READY as a stacked follow-up branch.

The branch was rebased on 2026-07-08 onto the latest #3291 parser commit:

```text
6e24b3b44a tests: preserve integer stats parser values
```

Current PR2 candidate commit:

```text
595c27591b tests: add stats reset validation
```

The PR2-only diff against `stats-txt-parser-pyunit` is narrow:

```text
tests/gem5/stats/configs/stats_reset_check.py |  50 ++++++++
tests/gem5/stats/test_stats_reset.py          | 162 ++++++++++++++++++++++++++
2 files changed, 212 insertions(+)
```

## Checks run on 2026-07-08

```sh
git rev-list --left-right --count stats-txt-parser-pyunit...stats-reset-validator
```

Result: `0 1`.

```sh
git merge-base --is-ancestor stats-txt-parser-pyunit stats-reset-validator
```

Result: passed.

```sh
git diff --check stats-txt-parser-pyunit...HEAD
```

Result: passed.

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/gem5/stats/configs/stats_reset_check.py \
  tests/gem5/stats/test_stats_reset.py
```

Result: passed.

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
```

Result: passed, 10 tests.

```sh
cd tests && ./main.py list -q --suites | grep -i stats
```

Result included:

```text
SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

The reset validator targets `NULL` because the config uses only
`ScalarStatTester` and has no ISA-specific setup.

```sh
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Result: passed, 10 tests.

```sh
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

Result: passed twice, 2 tests per run.

## Local Build Note

```sh
scons build/ALL/gem5.opt -j4
```

Result: failed at link in this container with protobuf/absl undefined
references. The local protobuf installation is inconsistent:

```text
pkg-config protobuf: 3.12.4
protoc: 25.3
/usr/include/google/protobuf: 25.3 headers
```

Workaround used only for local validation: build `NULL` with
`PROTOC=/bin/false` and `USE_TEST_OBJECTS=y`, producing a working
`build/NULL/gem5.opt` with `HAVE_PROTOBUF=0`.

## Historical execution evidence

Before the local `gem5.opt` environment broke:

- The reset suite passed twice with `--skip-build`.
- The parser pyunit runner passed under `gem5.opt`.
- The failure-mode check with `AFTER_RESET_TICKS = 20` failed as expected with
  an actionable `simTicks` before/after message, then passed after reverting
  to 1.

## Open action after PR #3291 merges

1. Fetch upstream `develop`.
2. Rebase `stats-reset-validator` onto the updated `develop`.
3. Re-run with a clean upstream-base `build/NULL/gem5.opt`:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

4. Confirm the upstream diff contains only:

```text
tests/gem5/stats/configs/stats_reset_check.py
tests/gem5/stats/test_stats_reset.py
```

5. Open the PR with title:

```text
tests: validate m5.stats.reset output
```

Opening packet:

```text
27_pr2_opening_packet.md
```
