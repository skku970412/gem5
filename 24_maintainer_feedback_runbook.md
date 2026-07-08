# Maintainer feedback runbook

Last refreshed: 2026-07-07 08:38:47 UTC

## Current upstream PRs

- #3291 parser PR:
  https://github.com/gem5/gem5/pull/3291
- #3292 CHI case-fix PR:
  https://github.com/gem5/gem5/pull/3292
- #3293 canonicalizer draft PR:
  https://github.com/gem5/gem5/pull/3293
- #3241 review-support comment:
  https://github.com/gem5/gem5/pull/3241#issuecomment-4901121740

Latest check summary:

- #3291: parser PR remains open/mergeable; only observed failure is still the
  unrelated `macos-compilation (opt)` CHI include-case issue; some CI remains
  queued or in progress.
- #3292: CHI case-fix PR remains open/mergeable; `pre-commit.ci - pr` passed;
  gem5 `CI Tests` run is `action_required` with no jobs started. A short
  status comment was posted:
  https://github.com/gem5/gem5/pull/3292#issuecomment-4901804485
- #3293: canonicalizer PR remains open/draft/mergeable; `pre-commit.ci - pr`
  passed; gem5 `CI Tests` runs are `action_required` while the PR is draft or
  unapproved.
- #3241: review target remains open/mergeable; all observed checks pass except
  `clang-format-check`, matching the already posted review-support comment.
- No maintainer comments or reviews have been added on #3291, #3292, #3293, or
  #3241 since the local comments were posted.
- Copy-edit-ready reply snippets are in `29_maintainer_response_templates.md`.

## Branch map

- `stats-txt-parser-pyunit`: parser PR #3291
- `stats-reset-validator`: stacked reset validator branch, not opened upstream
- `stats-reset-validation-docs`: stacked docs branch, not opened upstream
- `fix-chi-protocol-case`: CHI case-fix PR #3292
- `stats-name-canonicalizer`: draft canonicalizer PR #3293
- `review-pr-3241`: local review branch for PR #3241

## If #3291 asks for parser changes

Work branch:

```sh
git switch stats-txt-parser-pyunit
```

Keep the scope limited to:

- `tests/pyunit/stats/stats_txt.py`
- `tests/pyunit/stats/pyunit_stats_txt.py`
- `tests/pyunit/stats/fixtures/*`

Preferred verification:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
git diff --check origin/develop...HEAD
```

If the API location is challenged:

- First ask whether maintainers prefer `tests/pyunit/stats`, `tests/gem5/stats`,
  or a shared helper location.
- Avoid moving it into simulator source unless maintainers explicitly request a
  non-test utility.

If parser behavior is challenged:

- Preserve stat names exactly.
- Preserve `::` substat suffixes.
- Keep multi-dump ordering.
- Do not change gem5 stats output format.

## If #3291 maintainers object to the unrelated macOS failure

Point to:

- Existing comment:
  https://github.com/gem5/gem5/pull/3291#issuecomment-4900941873
- Separate fix PR:
  https://github.com/gem5/gem5/pull/3292

Do not merge CHI changes into #3291 unless explicitly requested.

## If #3292 asks for CHI case-fix changes

Work branch:

```sh
git switch fix-chi-protocol-case
```

Primary verification:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
scons build/ALL/python/_m5/param_CHIGenericController.o -j4
scons build/ALL/mem/ruby/protocol/CHI/generic/CHIGenericController.o \
      build/ALL/mem/ruby/protocol/CHI/generic/CBusy.o \
      build/ALL/python/_m5/param_CHIGenericController.o -j4
```

If maintainers dislike the directory rename:

- Ask whether they prefer changing generated include spelling, source mirror
  spelling, or SLICC protocol output naming.
- Do not rework SLICC generation broadly without explicit guidance.

## If #3291 is merged

Next action:

```sh
git fetch origin
git switch stats-reset-validator
git rebase origin/develop
```

Then verify that only reset-validator files remain:

```sh
git diff --name-only origin/develop...HEAD
```

Expected files:

- `tests/gem5/stats/configs/stats_reset_check.py`
- `tests/gem5/stats/test_stats_reset.py`

Run:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Open PR title:

```text
tests: validate m5.stats.reset output
```

## If reset-validator review asks for broader stats

Default response:

- Keep the first PR narrow unless maintainers specifically request more stats.
- Add one deterministic stat at a time.
- Avoid host/runtime stats unless the test documents why they are excluded.
- Preserve same-invocation before/reset/after generation.
- Do not add fixed reference stats files.

If adding a stat:

- Confirm it appears in both dumps or explicitly handle omitted-zero behavior.
- Add a failure message including stat name, before value, after value, and
  expected behavior.

## If reset-validator review asks about omitted zero stats

Current behavior:

- Missing after-reset stat is treated as zero only in the verifier path for
  resettable stats.

Response:

- This matches text stats behavior where zero-valued stats may be omitted.
- If maintainers prefer stricter behavior, require explicit presence for the
  first checked stats and remove absent-as-zero handling.

## If #3293 asks for canonicalizer changes

Work branch:

```sh
git switch stats-name-canonicalizer
```

Primary verification:

```sh
python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util
pre-commit run --files util/stats_canonicalizer.py tests/pyunit/util/pyunit_stats_canonicalizer.py
git diff --check origin/develop...HEAD
```

Preserve these compatibility constraints:

- Do not change default gem5 stats output.
- Do not change SimObject naming.
- Do not silently guess digit-suffix names without `config.json`.
- Preserve `::` substat suffixes.
- Keep collision detection on by default.

If maintainers want it non-draft:

- Confirm they accept the optional sidecar-tool direction.
- Mark ready only after any requested naming/location changes are handled.

## If #3241 maintainers ask for test help

Work branch:

```sh
git switch review-pr-3241
```

First ask whether they want:

- a small patch on the existing PR branch, or
- a follow-up PR after #3241 merges.

Highest-value tests:

- missing `name::subname` fails clearly
- `scalar_stat::subname` fails clearly
- malformed colon expressions fail clearly
- `VectorInfo` support or documented FormulaInfo-only limitation

Do not rewrite the implementation unless explicitly requested.

## If a maintainer asks what happens next

Short answer:

- #3291 is the parser utility PR.
- #3292 is a separate CI portability fix for the unrelated CHI include-case
  failure observed on #3291.
- PR2, `stats-reset-validator`, should open only after #3291 lands.
- PR3, `stats-reset-validation-docs`, should open only after PR2 lands.
- #3293 remains draft until maintainers confirm the optional sidecar
  canonicalizer direction for #2744.

Use `29_maintainer_response_templates.md` for ready-to-edit wording.

## If any branch needs force-push

Use:

```sh
git push --force-with-lease fork <branch>
```

Never force-push `origin`.

## Status files to update after changes

- `09_pr3291_ci_status.md`
- `14_pr3292_chi_case_status.md`
- `15_pr2744_canonicalizer_status.md`
- `19_open_pr_status.md`
- `20_oss_evidence_package.md`
- `22_pr3_docs_status.md`
- `23_branch_stack_matrix.md`
