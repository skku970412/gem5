# PR 2 Adversarial Review Notes

Branch: `stats-reset-validator`

Base for review: `stats-txt-parser-pyunit`

## Flakiness / Correctness Risks Checked

- The test generates both before-reset and after-reset dumps in one gem5 invocation.
- The test does not use fixed reference stats files.
- The test does not download resources or depend on an ISA-specific binary.
- The config uses existing `ScalarStatTester`, so runtime is short and deterministic.
- The verifier checks selected resettable stats only:
  - `system.reset_scalar`
  - `simTicks`
- Lifetime/constant/host stats are documented as not compared:
  - `finalTick`
  - `simFreq`
  - `hostSeconds`
  - `hostTickRate`
  - `hostMemory`
- The verifier treats a missing after-reset stat as zero to support zero-valued stats being omitted.
- The source tree stays clean after testlib runs.

## Destructive Check

Temporarily changed:

```python
AFTER_RESET_TICKS = 10
```

This makes the after-reset `simTicks` equal the before-reset `simTicks`.

Command:

```sh
cd tests
./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Expected result: failure.

Observed result: failure.

Failure evidence from `tests/testing-results/results.xml`:

```text
AssertionError: m5.stats.reset() validation failed for /tmp/gem5outovnphacr/stats.txt:
  - simTicks: before=10.0, after=10.0; expected after-reset value to be lower than before-reset value; simTicks reports ticks since the last stats reset.
```

The temporary change was reverted to:

```python
AFTER_RESET_TICKS = 1
```

The reset test then passed again.

## Latest Failure-Mode Recheck

Rechecked on 2026-07-07 07:48 UTC.

Temporarily changed:

```python
AFTER_RESET_TICKS = 20
```

Expected result: failure because `simTicks` after reset is not lower than the
before-reset value.

Observed result: failure.

Failure evidence from `tests/testing-results/results.xml`:

```text
AssertionError: m5.stats.reset() validation failed for /tmp/gem5out18tzsmhc/stats.txt:
  - simTicks: before=10.0, after=20.0; expected after-reset value to be lower than before-reset value; simTicks reports ticks since the last stats reset.
```

The temporary change was reverted to:

```python
AFTER_RESET_TICKS = 1
```

The reset test then passed again.

## Commands Run

```sh
scons build/ALL/gem5.opt -j4
```

Passed.

```sh
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Passed, 10 tests.
Rechecked on 2026-07-07 07:48 UTC: passed, 10 tests.

```sh
cd tests
./main.py list -q --suites gem5/stats
```

Listed:

```text
SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

```sh
cd tests
./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Passed. Re-run after edits also passed.
Rechecked on 2026-07-07 07:48 UTC: passed twice, then passed again after the
intentional failure-mode edit was reverted.

```sh
git diff --check stats-txt-parser-pyunit...HEAD
```

Passed.

```sh
pre-commit run --files $(git diff --name-only stats-txt-parser-pyunit...HEAD)
```

Passed.

## Reviewer Verdict

APPROVE WITH NITS.

Nits / follow-up:

- Wait for PR #3291 to merge before opening this as a normal upstream PR, otherwise the parser and reset validator appear in the same diff.
- Consider expanding the checked stats only after maintainer feedback.
