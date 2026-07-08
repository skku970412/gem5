# PR #3291 maintainer summary

Last refreshed: 2026-07-08 10:49 UTC

PR: https://github.com/gem5/gem5/pull/3291

Issue: https://github.com/gem5/gem5/issues/1644

## Current status

PR #3291 is open and contains a parser-only first step for #1644. It does not
change simulator behavior, stats output format, or system-level test behavior.

Latest pushed commit:

```text
6e24b3b44a tests: preserve integer stats parser values
```

Current diff against `origin/develop`:

```text
10 files changed under tests/pyunit/stats
```

Files changed:

- `tests/pyunit/stats/__init__.py`
- `tests/pyunit/stats/fixtures/duplicate_stat.txt`
- `tests/pyunit/stats/fixtures/edge_values.txt`
- `tests/pyunit/stats/fixtures/empty_dump.txt`
- `tests/pyunit/stats/fixtures/malformed_line.txt`
- `tests/pyunit/stats/fixtures/multiple_dumps.txt`
- `tests/pyunit/stats/fixtures/no_dump.txt`
- `tests/pyunit/stats/fixtures/single_dump.txt`
- `tests/pyunit/stats/pyunit_stats_txt.py`
- `tests/pyunit/stats/stats_txt.py`

The branch is currently `2 5` against `origin/develop`: two upstream commits
behind and five parser PR commits ahead. Do not rebase just for this unless
maintainers request it or CI/review clearly needs it, because a force-push can
restart review/check state.

## Reviewer feedback addressed

Copilot review:

- Concern: parsing every value with `float(...)` can lose precision for large
  integer counters and ticks.
- Fix: integer-looking tokens now parse through `int(...)` first. Decimal,
  scientific notation, `nan`, and `inf` still parse as `float`.
- Test added: `18446744073709551615` is parsed and asserted as an `int`.

Erin Le review:

- Concern: new file copyright holder should be the contributor's school or
  company, not the inherited UC copyright.
- Fix: both new Python files now use `Sungkyunkwan University`.

Response drafts:

- `41_pr3291_review_response.md`

## What the parser covers

- Multiple stats dumps in one `stats.txt`.
- Dump messages, such as `before reset` and `after reset`.
- Ordered dump output.
- Exact stat names, including `::` substat suffixes.
- Integer, float, scientific notation, negative, `nan`, and `inf` values.
- Large integer counters/ticks without float rounding.
- Trailing descriptions and percentage columns after the primary value.
- Oneline vector/distribution rows are skipped rather than synthesized.
- Duplicate stat names and malformed values fail clearly.

## Why this PR is separate from reset validation

Issue #1644 needs a reset validator that compares before/reset/after dumps
generated in one test invocation. The parser is the smallest reusable piece
needed by that validator.

Keeping #3291 parser-only means maintainers can review parsing behavior without
also reviewing simulator-level reset behavior.

The follow-up branch `stats-reset-validator` is prepared locally, but should
not be opened upstream until #3291 lands or maintainers explicitly accept a
stacked PR.

## Current verification summary

Passed on 2026-07-08 for commit `6e24b3b44a`:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
```

Result: 10 tests passed.

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
```

Result: passed.

```sh
git diff --check origin/develop...HEAD
git diff --check
```

Result: passed.

Remote:

- `pre-commit.ci - pr` passed on `6e24b3b44a`.

Passed in the current environment:

```sh
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Result: passed, 10 tests.

Default `ALL` build note:

```sh
scons build/ALL/gem5.opt -j4
```

failed at link in this container with protobuf/absl undefined references. The
local protobuf install is inconsistent: `pkg-config` reports protobuf 3.12.4
while `protoc` and headers are 25.3. This parser PR does not touch protobuf or
simulator build behavior.

## Remote PR state note

As of the latest web check, #3291 is still open. Erin/Copilot review comments
are addressed in code, BobbyRBruce is still listed as awaiting review, and no
approving maintainer review is visible yet.

The remote #3291 PR body still says values are parsed with Python `float` and
still lists the older `ALL/gem5.opt` build and pyunit runner as passed. Update
the remote PR body from `03_pr1_body.md` when GitHub auth or browser access is
available.

## Draft response if maintainers ask for a concise summary

```markdown
This PR is intentionally parser-only. It adds a test-local parser for
multi-dump `stats.txt` files under `tests/pyunit/stats` and fixture coverage
for dump ordering, `::` substat names, numeric edge values, trailing
descriptions/percentage columns, empty/no-stat dumps, malformed values, and
duplicates.

I addressed the review comments in `6e24b3b44a`: integer-looking values now
parse as `int` to preserve large counters/ticks, decimal/scientific/`nan`/`inf`
values remain floats, and the new file copyright holder is
`Sungkyunkwan University`.

It does not change simulator behavior or the stats output format. The follow-up
reset validator for #1644 is prepared separately so this PR stays small.
```
