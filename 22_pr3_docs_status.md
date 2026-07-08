# PR 3 stats reset documentation status

Branch: `stats-reset-validation-docs`

Fork branch: https://github.com/skku970412/gem5/tree/stats-reset-validation-docs

Commit: `4dfa1b0ad9 tests: document stats reset validation`

Last refreshed: 2026-07-07 08:22:34 UTC

## Current status

- Local docs implementation is committed.
- Branch is pushed to the fork.
- No upstream PR opened yet.
- This is stacked on `stats-reset-validator`, which is stacked on
  `stats-txt-parser-pyunit`.

Do not open this as an upstream PR until the parser and reset-validator PRs are
ready in order. Opening it now would include the parser and reset-validator
changes in the docs PR diff.

## Scope

Documentation only:

- `tests/gem5/stats/README.md`

## Changes

- Fix the README's opening grammar.
- Correct the listed Python stats output test name from `test_simstats_output`
  to `test_pystat_output`.
- Add `test_stats_reset` to the stats test list.
- Document how reset validation works:
  - before/reset/after dumps generated in one gem5 invocation
  - no fixed reference stats file dependency
  - selected resettable stats only
  - lifetime/constant/host-side stats excluded from comparison
  - zero-valued stats may be omitted
  - failure messages should include stat name, before value, after value, and
    expected reset behavior
- Add the targeted reset test command.

## Verification

```sh
git diff --check stats-reset-validator...HEAD
```

Passed. Rechecked on 2026-07-07 08:22 UTC.

```sh
pre-commit run --files tests/gem5/stats/README.md
```

Passed. Rechecked on 2026-07-07 08:22 UTC.

```sh
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Passed: 2 tests. Rechecked on 2026-07-07 08:22 UTC.

Opening packet:

```text
28_pr3_opening_packet.md
```

## Suggested PR title

`tests: document stats reset validation`

## Suggested PR description

Summary:

- Document the stats reset validation test in `tests/gem5/stats/README.md`.
- Explain why the test generates before/reset/after dumps in one invocation.
- Note why fixed reference stats files are avoided.
- Describe resettable vs lifetime/constant/host-side stats and omitted-zero
  behavior.

Testing:

- `git diff --check stats-reset-validator...HEAD`
- `pre-commit run --files tests/gem5/stats/README.md`
- `cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt`

Follow-up:

- Open only after the parser and reset-validator PRs are ready in order.
