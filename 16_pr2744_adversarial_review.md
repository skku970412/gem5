# Issue #2744 canonicalizer adversarial review

Branch: `stats-name-canonicalizer`

Commit reviewed: `d2e5d52abd util: add experimental stats name canonicalizer`

Date: 2026-07-07

## Backwards-compatibility verdict

Approve.

The branch only adds:

- `util/stats_canonicalizer.py`
- `tests/pyunit/util/pyunit_stats_canonicalizer.py`

No simulator source files, default stats output paths, SimObject naming code, or
stats visitor behavior are changed.

## Collision-safety verdict

Approve.

The tool detects multiple old stat names mapping to one canonical name and
fails by default. `--allow-collisions` is required to write colliding output.

## Bug found

The stat-line regex accepted `nan` and `inf` without requiring a token boundary.
That meant non-stat lines such as:

```text
system.cpu0.units nanosecond
system.cpu0.note infinity
```

could be misread as stats with `nan` or `inf` values.

## Fix made

Changed the regex so a parsed value must be followed by whitespace/trailing
description or end-of-line.

Added `test_value_tokens_require_a_boundary` to verify those lines are
preserved and omitted from the mapping.

## Commands run

```sh
git diff --name-status origin/develop...HEAD
```

Only the utility and pyunit test file are changed.

```sh
git diff --name-only origin/develop...HEAD | rg '^(src|configs|python|build_opts|SConstruct|site_scons)/' || true
```

No simulator/config/build source files matched.

```sh
git diff --check origin/develop...HEAD
```

Passed.

```sh
python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v
```

Passed: 10 tests.

```sh
pre-commit run --files util/stats_canonicalizer.py tests/pyunit/util/pyunit_stats_canonicalizer.py
```

Passed after `black` reformatted the new regression test.

```sh
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util
```

Passed: 28 tests.

CLI checks:

- sample stats fixture canonicalized successfully
- canonicalizing the output a second time was idempotent
- collision fixture failed with `canonical name collision`
- real `configs/learning_gem5/part1/simple.py` output canonicalized
  successfully and remained idempotent

## Reviewer verdict

Approve with the regex-boundary bug fixed.
