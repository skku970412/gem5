# gem5 work index

Last refreshed: 2026-07-08 10:49:00 UTC

Start here when resuming this gem5 contribution work.

## Fast Commands

Refresh external PR/CI/issue state:

```sh
./34_refresh_gem5_status.sh
```

Verify local branch stack integrity and targeted tests:

```sh
./38_verify_gem5_stack.sh
```

Capture a Markdown status snapshot for PR/CI review history:

```sh
./39_capture_gem5_status_snapshot.sh
```

Open PR2 safely after #3291 merges:

```sh
./36_open_pr2_after_3291.sh
./36_open_pr2_after_3291.sh --create
```

Open PR3 safely after PR2 merges:

```sh
./37_open_pr3_after_pr2.sh
./37_open_pr3_after_pr2.sh --create
```

## Current State

Read first:

- `40_gem5_contribution_dashboard.md`: current single-page dashboard with
  open PR state, reviewer feedback, local code changes, and next action
- `33_current_waiting_state.md`: concise current wait/branch/next-action state
- `19_open_pr_status.md`: detailed open PR status log
- `30_next_action_checklist.md`: exact command sequences for review, merge,
  CI failure, PR2 open, and PR3 open
- `35_maintainer_followup_policy.md`: when to comment again and when to stay
  quiet
- `status_snapshots/`: timestamped local PR/CI snapshots created by
  `39_capture_gem5_status_snapshot.sh`

## Open Upstream Work

- #3291 parser PR:
  https://github.com/gem5/gem5/pull/3291
- #3292 CHI case-fix PR:
  https://github.com/gem5/gem5/pull/3292
- #3293 canonicalizer draft PR:
  https://github.com/gem5/gem5/pull/3293
- #3241 review-support comment:
  https://github.com/gem5/gem5/pull/3241#issuecomment-4901121740

## Branches

- `stats-txt-parser-pyunit`: parser PR #3291
- `stats-reset-validator`: stacked PR2 candidate
- `stats-reset-validation-docs`: stacked PR3 candidate
- `fix-chi-protocol-case`: CHI case-fix PR #3292
- `stats-name-canonicalizer`: draft canonicalizer PR #3293
- `review-pr-3241`: local branch for review support

## PR Body Files

- `31_pr2_body_current.md`: PR2 body for reset validator
- `32_pr3_body_current.md`: PR3 body for reset docs
- `18_pr2744_pr_description.md`: canonicalizer PR body source
- `13_chi_macos_case_pr_body.md`: CHI case-fix PR body source

## Opening Packets

- `27_pr2_opening_packet.md`: PR2 rebase/open plan and body
- `28_pr3_opening_packet.md`: PR3 rebase/open plan and body

## Review And Evidence

- `20_oss_evidence_package.md`: OSS/Codex application evidence package
- `24_maintainer_feedback_runbook.md`: branch-specific review response plan
- `29_maintainer_response_templates.md`: copy-edit-ready maintainer replies
- `41_pr3291_review_response.md`: response drafts for the latest #3291 review
  comments
- `42_manual_github_updates.md`: browser/manual update checklist for stale
  remote PR bodies, titles, and comments when `gh` auth is unavailable
- `43_apply_github_pr_updates.sh`: dry-run-first API helper for applying the
  same stale PR body/title updates when `GITHUB_TOKEN` is available
- `35_maintainer_followup_policy.md`: follow-up timing and wording rules

Latest confirmed state:

- #3291 code branch is current at `6e24b3b44a` in the fork.
- Erin/Copilot review comments on #3291 are addressed in code.
- No approving maintainer review is visible yet.
- The GitHub #3291 body is still stale and should be replaced with
  `03_pr1_body.md` from the browser or via `43_apply_github_pr_updates.sh`
  once `GITHUB_TOKEN` is available.
- Local API auth state: no `GH_TOKEN`, no `GITHUB_TOKEN`, and `gh` is not
  installed.

## Historical Notes

- `01_repo_scout_1644.md`: initial #1644 repo scout
- `02_issue_1644_comment.md`: #1644 issue comment draft
- `05_pr1_adversarial_review.md`: parser adversarial review
- `07_pr2_adversarial_review.md`: reset validator adversarial review
- `08_issue_2744_design_report.md`: #2744 design investigation
- `11_pr3241_review_support.md`: #3241 review support notes

## Rule Of Thumb

- If nothing changed externally, do not post a new GitHub comment.
- If a PR gets maintainer feedback, update only the relevant branch and rerun
  the targeted checks in `30_next_action_checklist.md`.
- If #3291 merges, run `36_open_pr2_after_3291.sh`.
- If PR2 merges, run `37_open_pr3_after_pr2.sh`.
- If unsure what changed, run both:

```sh
./34_refresh_gem5_status.sh
./38_verify_gem5_stack.sh
```

- If you need a durable local record before/after fixing a CI failure, run:

```sh
./39_capture_gem5_status_snapshot.sh
```
