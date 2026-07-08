# PR #3291 CI status

PR: https://github.com/gem5/gem5/pull/3291

Checked on: 2026-07-07

Last refreshed: 2026-07-07 08:19:13 UTC

## Current PR state

- State: open
- Mergeable: mergeable
- Review decision: review required
- Comments: 2
- Reviews: 0
- Branch: `skku970412:stats-txt-parser-pyunit`
- Base: `gem5:develop`

## Passing checks observed

- `pre-commit`
- `clang-format-check`
- `clang-fast-compilation`
- `get-date`
- `testlib-quick-matrix`
- `macos-compilation (fast)`
- `unittests-all-fast-opt (fast)`
- `unittests-all-fast-opt (opt)`
- `pre-commit.ci - pr`

## Pending / queued checks observed

- `gpu-tests` queued
- `testlib-quick-gem5-builds (/__w/gem5/gem5/build/ALL/gem5.opt)` queued

These states were current when rechecked with `gh pr checks` and the GitHub
Actions jobs API at 2026-07-07 08:19:13 UTC.

Run-level details from `gh run view 28842525705`:

- Workflow run state: `queued`
- Run created: 2026-07-07 04:54:29 UTC
- Run updated: 2026-07-07 06:10:28 UTC
- `gpu-tests` job state: `queued`, started at 2026-07-07 06:10:27 UTC,
  no completion timestamp yet, no runner assigned, labels:
  `self-hosted`, `linux`, `x64`
- `testlib-quick-gem5-builds` job state: `queued`, started at
  2026-07-07 06:11:22 UTC, no completion timestamp yet, no runner assigned,
  labels: `self-hosted`, `linux`, `x64`

This points to self-hosted runner/job scheduling state, not a parser failure.

## Failing check observed

- `macos-compilation (opt)`
- Job: https://github.com/gem5/gem5/actions/runs/28842525705/job/85548461551

Relevant log excerpt:

```text
src/mem/ruby/protocol/chi/generic/CHIGenericController.hh:51:10:
error: non-portable path to file '"mem/ruby/protocol/chi/CHIDataMsg.hh"';
specified path differs in case from file name on disk
[-Werror,-Wnonportable-include-path]

    51 | #include "mem/ruby/protocol/CHI/CHIDataMsg.hh"
       |          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       |          "mem/ruby/protocol/chi/CHIDataMsg.hh"
```

The same job reports equivalent errors for:

- `CHIDataType.hh`
- `CHIRequestMsg.hh`
- `CHIRequestType.hh`
- `CHIResponseMsg.hh`
- `CHIResponseType.hh`

## Assessment

This failure is unrelated to PR #3291. The parser PR only changes Python test
utility files under `tests/pyunit/stats`. The failing job is compiling CHI Ruby
protocol generated/source headers on macOS and hitting a case-sensitive include
path warning promoted to an error.

Do not add a CHI include-path fix to PR #3291. That would make the parser PR no
longer small and focused.

## Recommended next action

1. Leave PR #3291 as-is unless a maintainer asks for changes.
2. Monitor the queued jobs until they settle.
3. If maintainers want help, open a separate focused issue/PR for the CHI
   macOS include-path problem.

## PR comment posted

Posted an explanation that the macOS opt failure appears unrelated and that this
PR should stay scoped to the stats parser utility:

https://github.com/gem5/gem5/pull/3291#issuecomment-4900941873

Posted a follow-up after opening a separate focused CHI case-fix PR:

https://github.com/gem5/gem5/pull/3291#issuecomment-4901203789

Separate PR:

https://github.com/gem5/gem5/pull/3292

Latest #3292 status observed:

- Open and mergeable
- `pre-commit.ci - pr` passed
- gem5 GitHub Actions is `action_required`, with no jobs created yet
- Head commit: `ff8edc4333d01e3b18bf15cabb0a41767fb89485`

## Local cleanup

Removed generated `stats.json` created while probing JSON stats output. The gem5
worktree was clean afterward.

## Additional parser smoke

Rechecked locally on 2026-07-07 08:13 UTC:

```sh
./build/ALL/gem5.opt --outdir=<tmpdir> configs/learning_gem5/part1/simple.py
PYTHONPATH=tests python3 - <<'PY'
from pathlib import Path
from pyunit.stats.stats_txt import parse_stats_file
stats_path = Path("<tmpdir>") / "stats.txt"
dumps = parse_stats_file(stats_path)
print(len(dumps))
print(dumps[0].stats["simTicks"])
print(dumps[0].stats["simInsts"])
print(dumps[0].stats["system.cpu.numCycles"])
PY
```

Result:

- parsed 1 real `stats.txt` dump
- `simTicks = 505816000.0`
- `simInsts = 6448.0`
- `system.cpu.numCycles = 505816.0`
- 609 parsed stats total

## Latest local parser gate

Rechecked on 2026-07-07 08:13 UTC after fetching `origin/develop`:

```sh
git rev-list --left-right --count origin/develop...HEAD
```

Result: `0 4`, so the branch was not behind upstream `develop`.

```sh
git diff --check origin/develop...HEAD
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Result: all passed.
