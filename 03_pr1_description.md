Title:
tests: add stats.txt parser utility

Summary:
- Add a small Python parser for text `stats.txt` files with one or more stats
  dumps.
- Preserve stat names as emitted, including names with `::`, brackets,
  hyphens, dots, and digits.
- Add fixture-based pyunit coverage for scalar stats, multi-dump files, edge
  numeric values, malformed input, malformed dump boundaries, duplicate names,
  and empty/no-dump files.

Motivation:
- This is a non-invasive first step toward #1644.
- A follow-up reset validation test can generate before/reset/after dumps in
  one invocation and compare selected resettable stats without relying on
  fixed reference stats files.

Implementation:
- Adds `tests/pyunit/stats/stats_txt.py`.
- Represents each dump as a `StatsDump` with ordered stat values and optional
  dump message text.
- Parses integer-looking values as `int` so large counters and ticks are not
  rounded through `float`.
- Parses decimal, scientific notation, `nan`, and `inf` values as `float`.
- Ignores text outside dump delimiters and skips valid `statistics::oneline`
  rows instead of synthesizing stat names.
- Raises `StatsParseError` for malformed stat values, duplicate stat names
  within one dump, unterminated dumps, and end-before-begin delimiters.
- Keeps the utility test-local and does not change simulator behavior or stats
  output.

Testing:
- [x] `python3 -m py_compile tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py`
  passed.
- [x] `python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v`
  passed, 12 tests.
- [x] `python3 -m unittest discover -s tests/pyunit -p 'pyunit_stats_txt.py' -v`
  passed, 12 tests.
- [x] `PATH="$HOME/.local/bin:$PATH" pre-commit run --files tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py tests/pyunit/stats/fixtures/edge_values.txt`
  passed.
- [x] Hidden/control character scan passed for source and fixture files under
  `tests/pyunit/stats`.
- [x] `git diff --check origin/develop...HEAD` passed.
- [x] `git diff --check` passed.
- [x] `pre-commit.ci - pr` passed on commit `6e24b3b44a`; awaiting rerun on
  latest commit `240b6f0961`.
- [x] `./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
  passed, 12 tests.
- [ ] `scons build/ALL/gem5.opt -j4` could not be completed in the current
  container. The default `ALL` build failed at link with protobuf/absl
  undefined references due a local protobuf/protoc/header/library mismatch
  (`pkg-config` reports protobuf 3.12.4 while `protoc` and headers are 25.3).
  The parser change is test-local and does not touch protobuf or simulator
  build behavior.

Compatibility:
- Does not change simulator behavior or text stats output.
- Does not add external dependencies.
- Keeps parser behavior test-local for now.

Follow-up:
- Add a `m5.stats.reset()` validation test that generates before/after dumps
  in the same gem5 invocation and uses this parser to compare a narrow set of
  resettable stats.
