# gem5 next-action checklist

Last refreshed: 2026-07-08 05:48:00 UTC

Top-level index: `00_gem5_work_index.md`

This file is the operational checklist for continuing the current gem5
contribution work. Re-check GitHub before acting; do not rely on this file as
live state.

## Fast Status Refresh

Run from `gem5/`:

```sh
gh pr view 3291 --repo gem5/gem5 --json state,isDraft,mergeable,reviewDecision,updatedAt
gh pr checks 3291 --repo gem5/gem5
gh pr view 3292 --repo gem5/gem5 --json state,isDraft,mergeable,reviewDecision,updatedAt
gh pr checks 3292 --repo gem5/gem5
gh pr view 3293 --repo gem5/gem5 --json state,isDraft,mergeable,reviewDecision,updatedAt
gh pr checks 3293 --repo gem5/gem5
gh pr view 3241 --repo gem5/gem5 --json state,mergeable,reviewDecision,updatedAt,comments,reviews
```

Or run the local wrapper from this directory:

```sh
./34_refresh_gem5_status.sh
```

The wrapper also prints related issue state, PR merge-state fields, #3291
queued job labels/runner assignment, and action hints.

If `gh` is unavailable or GitHub API access is rate-limited, use:

```text
42_manual_github_updates.md
```

If `GITHUB_TOKEN` or `GH_TOKEN` is available, use the dry-run-first helper:

```sh
./43_apply_github_pr_updates.sh --dry-run
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply
```

To verify local branch stack structure and targeted tests:

```sh
./38_verify_gem5_stack.sh
```

To capture a timestamped Markdown snapshot before/after PR triage:

```sh
./39_capture_gem5_status_snapshot.sh
```

Expected current state:

- #3291: open; review comments addressed at `6e24b3b44a`; remote PR body is
  stale and should be updated from `03_pr1_body.md`.
- #3292: open; smaller no-directory-rename CHI generated-header include fix
  force-pushed at `1f32ed40c3`; remote title/body still describe the old
  directory rename and should be updated from `13_chi_macos_case_pr_body.md`.
- #3293: draft, open, mergeable, review required; `pre-commit.ci - pr` passes;
  gem5 `CI Tests` is `action_required` while draft/unapproved.
- #3241: open, mergeable, review required; no response yet to the test-gap
  comment.
- PR2 local branch: `stats-reset-validator` is rebased on current #3291 at
  `9a0c8ee86e` and pushed to the fork.
- PR3 local branch: `stats-reset-validation-docs` is rebased on current PR2 at
  `fedbb9f97e` and pushed to the fork.
- `origin/develop...stats-txt-parser-pyunit` is currently `2 5`; do not rebase
  the open parser PR solely for this drift unless maintainers request it.
- Current concise waiting-state snapshot:
  `33_current_waiting_state.md`
- Follow-up/ping rules:
  `35_maintainer_followup_policy.md`

## If #3291 Gets Review Comments

Work branch:

```sh
git switch stats-txt-parser-pyunit
```

Keep changes limited to:

```text
tests/pyunit/stats/__init__.py
tests/pyunit/stats/fixtures/*
tests/pyunit/stats/pyunit_stats_txt.py
tests/pyunit/stats/stats_txt.py
```

Verification:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
git diff --check origin/develop...HEAD
```

Push:

```sh
git push fork stats-txt-parser-pyunit
```

If the PR body must be updated manually, use `03_pr1_body.md`. Do not keep the
old float-only parser wording or the old latest-commit `gem5.opt` pyunit pass
claim.

## If Any PR Check Fails

First capture the current state:

```sh
./39_capture_gem5_status_snapshot.sh
```

Then inspect the failing job before editing. Use the URL from
`gh pr checks <pr>` or:

```sh
gh run view <run-id> --repo gem5/gem5 --log-failed
```

Classification:

- In-scope failure: fix the current PR branch only, rerun the narrow targeted
  command, then rerun `git diff --check` and pre-commit for changed files.
- Unrelated failure: do not mix the fix into the current PR. Document evidence
  in the PR only if it is blocking review, and create a separate focused branch
  only when the failure has a small obvious fix.
- Infrastructure or approval issue: do not push code. Wait unless the
  maintainer follow-up policy says a concise status comment is useful.

After fixing an in-scope failure, capture a second snapshot so the before/after
state is recoverable:

```sh
./39_capture_gem5_status_snapshot.sh
```

## If #3291 Merges

Open PR2 only after rebasing so the diff is reset-validator only.

Preferred guarded helper:

```sh
./36_open_pr2_after_3291.sh
```

The helper exits without changing branches if #3291 is not merged. After the
dry run passes, create the PR with:

```sh
./36_open_pr2_after_3291.sh --create
```

```sh
git fetch origin
git switch stats-reset-validator
git rebase origin/develop
git diff --name-only origin/develop...HEAD
```

Expected diff:

```text
tests/gem5/stats/configs/stats_reset_check.py
tests/gem5/stats/test_stats_reset.py
```

Verification:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Push and open:

```sh
git push --force-with-lease fork stats-reset-validator
gh pr create --repo gem5/gem5 --base develop --head skku970412:stats-reset-validator --title "tests: validate m5.stats.reset output" --body-file ../31_pr2_body_current.md
```

Before opening, compare `31_pr2_body_current.md` with
`27_pr2_opening_packet.md`; they should describe the same current verification.

## If #3292 Gets Review Comments

Work branch:

```sh
git switch fix-chi-protocol-case
```

Keep scope limited to CHI directory/include/path casing. Do not mix stats
changes into this branch.

Verification:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files $(git diff --name-only origin/develop...HEAD)
scons build/ALL/python/_m5/param_CHIGenericController.o -j4
scons build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o \
      build/ALL/mem/ruby/protocol/chi/generic/CBusy.o \
      build/ALL/python/_m5/param_CHIGenericController.o -j4
```

## If PR2 Merges

Open PR3 only after rebasing so the diff is docs-only.

Preferred guarded helper:

```sh
./37_open_pr3_after_pr2.sh
```

The helper exits without changing branches if `stats-reset-validator` is not
yet in `origin/develop`. After the dry run passes, create the PR with:

```sh
./37_open_pr3_after_pr2.sh --create
```

```sh
git fetch origin
git switch stats-reset-validation-docs
git rebase origin/develop
git diff --name-only origin/develop...HEAD
```

Expected diff:

```text
tests/gem5/stats/README.md
```

Verification:

```sh
git diff --check origin/develop...HEAD
pre-commit run --files tests/gem5/stats/README.md
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
```

Push and open:

```sh
git push --force-with-lease fork stats-reset-validation-docs
gh pr create --repo gem5/gem5 --base develop --head skku970412:stats-reset-validation-docs --title "tests: document stats reset validation" --body-file ../32_pr3_body_current.md
```

Before opening, compare `32_pr3_body_current.md` with
`28_pr3_opening_packet.md`; they should describe the same current verification.

## If #3293 Gets Direction From Maintainers

Work branch:

```sh
git switch stats-name-canonicalizer
```

If maintainers accept the optional sidecar direction, handle requested edits
then mark ready only after verification.

Verification:

```sh
python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util
pre-commit run --files util/stats_canonicalizer.py tests/pyunit/util/pyunit_stats_canonicalizer.py
git diff --check origin/develop...HEAD
```

Mark ready:

```sh
gh pr ready 3293 --repo gem5/gem5
```

Do not mark ready if the maintainer direction is still unclear.

## If #3241 Asks For Help

Do not take over the PR. Ask whether the author/maintainers prefer a patch on
the PR branch or a follow-up PR after merge.

Highest-value tests to add if requested:

- missing `name::subname` fails clearly
- `scalar_stat::subname` fails clearly
- malformed colon syntax fails clearly
- `VectorInfo` support or documented FormulaInfo-only limitation

## Files To Update After Meaningful Progress

- `19_open_pr_status.md`
- `00_gem5_work_index.md`
- `20_oss_evidence_package.md`
- `23_branch_stack_matrix.md`
- `24_maintainer_feedback_runbook.md`
- `27_pr2_opening_packet.md`
- `28_pr3_opening_packet.md`
- `29_maintainer_response_templates.md`
- `30_next_action_checklist.md`
- `31_pr2_body_current.md`
- `32_pr3_body_current.md`
- `33_current_waiting_state.md`
- `34_refresh_gem5_status.sh`
- `35_maintainer_followup_policy.md`
- `36_open_pr2_after_3291.sh`
- `37_open_pr3_after_pr2.sh`
- `38_verify_gem5_stack.sh`
- `39_capture_gem5_status_snapshot.sh`
- `status_snapshots/`
