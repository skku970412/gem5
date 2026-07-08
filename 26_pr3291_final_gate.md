# PR #3291 final gate

PR: https://github.com/gem5/gem5/pull/3291

Issue: https://github.com/gem5/gem5/issues/1644

Last refreshed: 2026-07-08 07:45 UTC

## Verdict

READY from the branch/content side, with one documentation action still needed
on GitHub:

- The branch contains one logical parser-only change.
- Latest review comments have been addressed in `6e24b3b44a`.
- Local targeted parser verification passed.
- Remote PR body is stale and should be updated from `03_pr1_body.md` when
  GitHub auth/browser access is available.

Do not claim the default `ALL` build passed. The latest parser pyunit runner
passed under local `build/NULL/gem5.opt`; the default `ALL` build failed in
this container due a local protobuf/protoc/header/library mismatch unrelated
to this parser PR.

## Scope check

The PR is one logical change: a test-local `stats.txt` parser and parser tests.

Files:

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

No simulator behavior, stats output format, generated files, broad refactors,
or unrelated formatting changes are included.

## Review fixes

Latest commit:

```text
6e24b3b44a tests: preserve integer stats parser values
```

Fixed:

- Integer-looking values now parse as `int`.
- Decimal/scientific/`nan`/`inf` values still parse as `float`.
- Fixture coverage now includes `18446744073709551615`.
- New Python file copyright holder is `Sungkyunkwan University`.

## Local gate evidence

Branch freshness:

```sh
git rev-list --left-right --count origin/develop...HEAD
```

Result:

```text
1 5
```

Interpretation: one upstream commit behind, five PR commits ahead. Do not
force-push solely for this unless maintainers request it.

Verification commands from the latest parser gate:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
```

Result: passed, 10 tests.

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

Remote check observed:

- `pre-commit.ci - pr` passed on `6e24b3b44a`.

```sh
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Result: passed, 10 tests.

## Local `ALL` Build Note

```sh
scons build/ALL/gem5.opt -j4
```

Result: failed at link in this container with protobuf/absl undefined
references due local protobuf mismatch (`pkg-config` protobuf 3.12.4, `protoc`
and headers 25.3). This parser PR does not touch protobuf or simulator build
behavior.

## Decision

No parser code change is currently indicated.

Next action:

- Update the remote #3291 PR body from `03_pr1_body.md` when GitHub auth or
  browser access is available.
- Optionally post the concise response from `41_pr3291_review_response.md`.
- Wait for maintainer review or CI changes.
