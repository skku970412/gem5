# PR 3 opening packet: stats reset documentation

Branch: `stats-reset-validation-docs`

Dependencies:

1. PR #3291 parser must merge.
2. PR 2 `stats-reset-validator` must merge.

Last refreshed: 2026-07-08 07:27 UTC

## Status

READY as a stacked docs follow-up, but not ready to open as a normal upstream
PR yet.

Do not open this against `gem5/develop` before the parser and reset-validator
changes merge. The diff would include the implementation stack instead of a
docs-only change.

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
git rev-list --left-right --count stats-reset-validator...stats-reset-validation-docs
```

Result: `0 1`.

```sh
git merge-base --is-ancestor stats-reset-validator stats-reset-validation-docs
```

Result: passed.

## PR3-Only Diff

Diff base: `stats-reset-validator...stats-reset-validation-docs`

```text
tests/gem5/stats/README.md | 45 ++++++++++++++++++++++++++++++++++++++++++---
1 file changed, 42 insertions(+), 3 deletions(-)
```

File:

- `tests/gem5/stats/README.md`

## Latest Verification

Passed on 2026-07-08 after rebasing onto PR2 commit `33d79e2c2e`:

```sh
git diff --check stats-reset-validator...stats-reset-validation-docs
```

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files tests/gem5/stats/README.md
```

Also passed on 2026-07-08 using the current PR2 stack and local
`build/NULL/gem5.opt`:

```sh
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

Result: passed twice, 2 tests per run.

Default `ALL` build note: `scons build/ALL/gem5.opt -j4` failed at link in
this container due local protobuf/protoc/header/library mismatch and
protobuf/absl undefined references. The PR3 docs are documentation-only; PR2
execution was verified with the smaller `NULL` target.

## Opening Steps After PR 2 Merges

```sh
git fetch origin
git switch stats-reset-validation-docs
git rebase origin/develop
git diff --name-only origin/develop...HEAD
```

Expected file:

```text
tests/gem5/stats/README.md
```

Run:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files tests/gem5/stats/README.md
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```

Push:

```sh
git push --force-with-lease fork stats-reset-validation-docs
```

Open the PR against `gem5:develop`.

## Suggested PR Title

```text
tests: document stats reset validation
```

## Suggested PR Body

Use `32_pr3_body_current.md` and refresh its Testing section after rerunning
with a clean upstream-base `build/NULL/gem5.opt`.
