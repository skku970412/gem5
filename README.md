# gem5 contribution log

This branch records the current gem5 contribution work, review state, PR body
drafts, verification commands, and follow-up plans. It is a tracking branch in
the `skku970412/gem5` fork, not an upstream gem5 PR branch.

## Start Here

- `40_gem5_contribution_dashboard.md`: single-page current status.
- `33_current_waiting_state.md`: concise waiting state and next action.
- `00_gem5_work_index.md`: index of all tracking documents and scripts.
- `30_next_action_checklist.md`: command sequences for review, merge, and
  follow-up PR handling.
- `42_manual_github_updates.md`: browser copy/paste steps when GitHub API auth
  is unavailable.

## Current PR Links

- PR #3291, stats parser:
  https://github.com/gem5/gem5/pull/3291
- PR #3292, CHI include case fix:
  https://github.com/gem5/gem5/pull/3292
- PR #3293, draft stats name canonicalizer:
  https://github.com/gem5/gem5/pull/3293
- Issue #1644, stats reset validation:
  https://github.com/gem5/gem5/issues/1644
- Issue #2744, canonical vector stats names:
  https://github.com/gem5/gem5/issues/2744
- Issue #3235, live stats lookup:
  https://github.com/gem5/gem5/issues/3235
- PR #3241, live stats lookup implementation by another contributor:
  https://github.com/gem5/gem5/pull/3241

## Relevant Review / Comment Links

- #3291 original author comment / PR body:
  https://github.com/gem5/gem5/pull/3291#issuecomment-4900941873
- #3291 follow-up CHI-scope note:
  https://github.com/gem5/gem5/pull/3291#issuecomment-4901203789
- #3291 Copilot integer precision review:
  https://github.com/gem5/gem5/pull/3291#discussion_r3540434772
- #3291 Erin copyright review on `pyunit_stats_txt.py`:
  https://github.com/gem5/gem5/pull/3291#discussion_r3540438739
- #3291 Erin copyright review on `stats_txt.py`:
  https://github.com/gem5/gem5/pull/3291#discussion_r3540443168
- #3241 review-support comment:
  https://github.com/gem5/gem5/pull/3241#issuecomment-4901121740

## Current Code Branches

- `stats-txt-parser-pyunit`: #3291, current head
  `240b6f0961 tests: cover stats parser malformed boundaries`
- `fix-chi-protocol-case`: #3292, current head
  `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`
- `stats-name-canonicalizer`: #3293 draft, current head
  `d2e5d52abd util: add experimental stats name canonicalizer`
- `stats-reset-validator`: PR2 candidate, current head
  `33d79e2c2e tests: add stats reset validation`
- `stats-reset-validation-docs`: PR3 candidate, current head
  `d176af0239 tests: document stats reset validation`

## Commands

Refresh local status:

```sh
cd /home/work/llama_young/for____what
./34_refresh_gem5_status.sh
./38_verify_gem5_stack.sh
```

Update #3291 PR body/comment if GitHub API auth is available:

```sh
cd /home/work/llama_young/for____what
./43_apply_github_pr_updates.sh --dry-run --only 3291 --post-comments
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply --only 3291 --post-comments
```

Manual #3291 update without API auth:

```text
1. Open https://github.com/gem5/gem5/pull/3291.
2. Replace the PR body with 03_pr1_body.md.
3. Optionally post the general response from 41_pr3291_review_response.md.
```

Run #3291 parser tests:

```sh
cd /home/work/llama_young/for____what/gem5
python3 -m py_compile tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
python3 -m unittest discover -s tests/pyunit -p 'pyunit_stats_txt.py' -v
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
git diff --check origin/develop...HEAD
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Open PR2 after #3291 merges:

```sh
cd /home/work/llama_young/for____what
./36_open_pr2_after_3291.sh
./36_open_pr2_after_3291.sh --create
```

Open PR3 after PR2 merges:

```sh
cd /home/work/llama_young/for____what
./37_open_pr3_after_pr2.sh
./37_open_pr3_after_pr2.sh --create
```

## Current Constraint

This shell has no GitHub API auth:

```text
GH_TOKEN unset
GITHUB_TOKEN unset
gh not installed
```

Git push over the configured SSH remote works, but editing PR bodies and
posting comments through the GitHub API requires a token or browser access.
