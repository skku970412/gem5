# Issue #2744 canonicalizer pre-PR gate

Branch: `stats-name-canonicalizer`

Commit: `d2e5d52abd util: add experimental stats name canonicalizer`

Checked on: 2026-07-07 07:37:28 UTC

Draft PR opened afterward: https://github.com/gem5/gem5/pull/3293

Latest PR status observed: draft, open, mergeable, `pre-commit.ci - pr`
passed on commit `d2e5d52abd`.

## Verdict

READY as a small technical PR.

Opened upstream as a draft/feedback PR because the #2744 maintainer-direction
comment had not received a response. Keep it draft until maintainers agree with
the sidecar-tool direction or request changes.

## Scope audit

- One logical change: optional sidecar stats-name canonicalizer.
- Default gem5 stats output unchanged.
- Simulator behavior unchanged.
- SimObject naming unchanged.
- No source/build/config files changed.
- No generated files in the git diff.

Changed files:

- `util/stats_canonicalizer.py`
- `tests/pyunit/util/pyunit_stats_canonicalizer.py`

## Commands run

```sh
git status --short --branch
```

Clean worktree on `stats-name-canonicalizer`.

```sh
git diff --stat origin/develop...HEAD
```

Two added files, 500 insertions.

```sh
git diff --check origin/develop...HEAD
```

Passed.

```sh
git diff --name-only origin/develop...HEAD
```

Only the utility and pyunit test file are changed.

```sh
git diff --name-only origin/develop...HEAD | rg '^(src|configs|python|build_opts|SConstruct|site_scons)/' || true
```

No output. No simulator/config/build source files changed.

```sh
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
```

Passed.

```sh
python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v
```

Passed: 10 tests.

```sh
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util
```

Passed: 28 tests. Existing convert tests printed expected warnings.

CLI smoke test:

- wrote canonicalized output
- wrote old-name to canonical-name mapping JSON
- verified a second canonicalizer pass is idempotent
- verified collision input fails with `canonical name collision`
- verified real `configs/learning_gem5/part1/simple.py` output canonicalizes
  without collisions and is idempotent

## Blocking issues

None in the branch.

## Non-blocking risks

- The tool is intentionally conservative and only canonicalizes paths proven by
  `config.json`; it does not infer ambiguous digit suffixes from `stats.txt`
  alone.
- This is a user-facing utility, so maintainer feedback on location and naming
  may still change the final shape.

## Suggested PR title

`util: add experimental stats name canonicalizer`

## Suggested PR description

See `18_pr2744_pr_description.md`.
