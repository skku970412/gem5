# PR #3291 review response draft

PR: https://github.com/gem5/gem5/pull/3291

Latest response commit: `6e24b3b44a tests: preserve integer stats parser values`

Last refreshed: 2026-07-08 10:49 UTC

Use these if GitHub auth/browser access is available.

## General PR comment

```markdown
Thanks for the review comments. I pushed `6e24b3b44a` addressing them:

- integer-looking stat values now parse as `int`, preserving large gem5
  counters/ticks beyond float's exact 53-bit range;
- decimal, scientific notation, `nan`, and `inf` values still parse as
  `float`;
- the edge-value fixture now covers `18446744073709551615`;
- the copyright holder in the new parser/test Python files is updated to
  `Sungkyunkwan University`.

Local checks:
- `python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v`
- `pre-commit run --files tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py tests/pyunit/stats/fixtures/edge_values.txt`
- `git diff --check origin/develop...HEAD`
- `git diff --check`
- `./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`

I also attempted a default `ALL` build, but this local container has an
inconsistent protobuf installation: `pkg-config` reports protobuf 3.12.4 while
`protoc` and headers are 25.3, and `scons build/ALL/gem5.opt -j4` failed at
link with protobuf/absl undefined references. The parser change is test-local
and does not touch protobuf or simulator build behavior.
```

## Copilot integer precision comment

```markdown
Addressed in `6e24b3b44a`. Integer-looking values now parse through `int(...)`
before falling back to `float(...)`, so large counters/ticks are preserved
without float rounding. I added a fixture assertion for
`18446744073709551615` and kept decimal/scientific/`nan`/`inf` coverage as
floats.
```

## Copyright comments

```markdown
Updated both new Python files to use `Sungkyunkwan University` as the copyright
holder in `6e24b3b44a`.
```
