# Issue #2744 optional stats name canonicalizer status

Issue: https://github.com/gem5/gem5/issues/2744

Issue comment: https://github.com/gem5/gem5/issues/2744#issuecomment-4900947219

Branch: `stats-name-canonicalizer`

Fork branch: https://github.com/skku970412/gem5/tree/stats-name-canonicalizer

Draft PR: https://github.com/gem5/gem5/pull/3293

Commit: `d2e5d52abd util: add experimental stats name canonicalizer`

Last refreshed: 2026-07-07 08:24:32 UTC

## Current status

- Local implementation is committed.
- Branch is pushed to the fork.
- Upstream draft PR #3293 is open and mergeable.
- The PR is intentionally marked draft while the optional sidecar-tool direction
  is still open for maintainer feedback.
- `pre-commit.ci - pr` passed.
- Rechecked locally on 2026-07-07 08:11 UTC; no code changes were needed.
- Updated the draft PR body on 2026-07-07 08:24 UTC to remove the duplicated
  `Title:` block, state why the PR is draft, and include the latest
  real-output smoke details.
- Posted a follow-up issue comment linking the draft PR:
  https://github.com/gem5/gem5/issues/2744#issuecomment-4901322340

## Scope

This is a backwards-compatible prototype for #2744. It does not change default
gem5 stats output, SimObject naming, or simulator behavior.

## Files changed

- `util/stats_canonicalizer.py`
- `tests/pyunit/util/pyunit_stats_canonicalizer.py`

## Design

- CLI accepts `--input`, `--output`, optional `--config-json`, optional
  `--mapping-output`, and `--allow-collisions`.
- Without `config.json`, the tool preserves stat names and does not guess from
  digit suffixes.
- With `config.json`, the tool uses explicit SimObjectVector lists to map
  actual paths like `system.cpu0` to canonical paths like `system.cpu[0]`.
- Length-one vectors are canonicalized when they appear as a list in
  `config.json`, for example `system.single` to `system.single[0]`.
- `::` substat suffixes are preserved.
- Comments/header/footer/non-stat lines are preserved.
- Multiple old names mapping to the same canonical name fail by default unless
  `--allow-collisions` is explicitly provided.

## Verification

```sh
python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v
```

Passed: 10 tests.
Rechecked on 2026-07-07 08:11 UTC.

```sh
pre-commit run --files util/stats_canonicalizer.py tests/pyunit/util/pyunit_stats_canonicalizer.py
```

Passed.
Rechecked on 2026-07-07 08:11 UTC.

```sh
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util
```

Passed: 28 tests. Existing convert tests printed expected warnings.
Rechecked on 2026-07-07 08:11 UTC.

```sh
git diff --check origin/develop...HEAD
```

Passed. Rechecked on 2026-07-07 08:11 UTC.

CLI smoke test:

- canonicalized `system.cpu0.numCycles` to `system.cpu[0].numCycles`
- wrote mapping JSON
- re-ran the canonicalizer on already-canonical output and verified
  idempotency
- intentionally created `system.cpu0.numCycles` plus
  `system.cpu[0].numCycles` and verified collision failure with a clear
  `canonical name collision` error
- ran the utility against a real `configs/learning_gem5/part1/simple.py`
  `stats.txt`/`config.json`; it produced 609 mapping entries, changed two
  names, and remained idempotent on the second pass
- latest real-output smoke changed:
  `system.cpu.interrupts.clk_domain.clock` to
  `system.cpu.interrupts[0].clk_domain.clock`, and
  `system.cpu.workload.numSyscalls` to
  `system.cpu.workload[0].numSyscalls`

## Adversarial review result

Verdict: approve with one bug fixed.

Bug found:

- The stat-value regex could treat words beginning with `nan` or `inf`, such as
  `nanosecond` or `infinity`, as numeric `nan`/`inf` values.

Fix:

- Require a value-token boundary: value is followed by whitespace/trailing
  description or end-of-line.
- Added `test_value_tokens_require_a_boundary` to ensure those lines are
  preserved and not included in the mapping.

Additional regression added:

- `test_distribution_columns_are_preserved` checks real `stats.txt`-style rows
  with trailing percentage columns after the primary value.

## Suggested PR title

`util: add experimental stats name canonicalizer`

## Suggested PR body

Summary:

- Add an optional sidecar utility for canonicalizing names in existing
  `stats.txt` files.
- Use `config.json` SimObjectVector metadata to canonicalize only paths that can
  be mapped safely.
- Add pyunit coverage for vector paths, length-one vectors, `::` substats,
  unchanged names, idempotency, and collision handling.

Compatibility:

- Default gem5 output is unchanged.
- Simulator behavior is unchanged.
- Ambiguous digit-suffix names are not guessed from `stats.txt` alone.

Testing:

- `python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v`
- `pre-commit run --files util/stats_canonicalizer.py tests/pyunit/util/pyunit_stats_canonicalizer.py`
- `./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util`
- CLI smoke, idempotency, and collision-failure checks
- Real gem5 output smoke using `configs/learning_gem5/part1/simple.py`

Follow-up:

- Monitor #3293 CI.
- Wait for maintainer feedback before marking the draft PR ready for review.
