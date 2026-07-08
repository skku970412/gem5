# Maintainer follow-up policy

Last refreshed: 2026-07-07 08:43:42 UTC

This file defines when to comment again on the open gem5 PRs. The goal is to
stay responsive without creating notification noise.

## General Rule

- Do not post a new comment just to say that nothing changed.
- Re-check current state before every comment with:

```sh
./34_refresh_gem5_status.sh
```

- Comment only when there is new information, a maintainer question, a changed
  CI result, or a long enough quiet period that a concise follow-up is useful.
- Prefer editing PR bodies for durable verification updates; prefer comments
  for new CI diagnosis or direct maintainer questions.

## #3291 Parser PR

Current state:

- Parser changes are stable and locally verified.
- `macos-compilation (opt)` failure is unrelated and covered by #3292.
- Two self-hosted jobs remain queued.

Do not comment again while:

- queued jobs are still queued,
- no maintainer has asked for parser changes,
- #3292 is still waiting for workflow approval/review.

Consider one short follow-up only if:

- self-hosted jobs remain queued for more than 48 hours from the last status
  comment, or
- #3292 is approved/merged and #3291 still shows the old unrelated macOS
  failure, or
- a maintainer asks whether #3291 should include the CHI fix.

Draft follow-up if needed:

```text
Quick status update: the parser PR itself is unchanged and still limited to
`tests/pyunit/stats`. The remaining non-parser CI issue is tracked separately
in #3292, and the self-hosted jobs still appear queued rather than failing in
parser code. I can rebase/re-run checks if maintainers prefer.
```

## #3292 CHI Case-Fix PR

Current state:

- `pre-commit.ci - pr` passes.
- gem5 `CI Tests` is `action_required` with zero jobs started.
- A status comment was posted:
  https://github.com/gem5/gem5/pull/3292#issuecomment-4901804485

Do not comment again while:

- `CI Tests` remains `action_required`,
- no maintainer has requested a different fix shape,
- no CI job has actually run and failed.

Consider one short follow-up only if:

- workflow approval occurs and CI fails,
- workflow approval has not happened after a full business day and #3291 is
  still blocked by the same unrelated macOS failure,
- a maintainer asks whether the directory rename is the smallest fix.

Draft follow-up if approval remains pending:

```text
Small follow-up: this PR still has no gem5 CI jobs started because the
`CI Tests` run is `action_required`. The branch-side checks remain local-only
until the workflow is approved. I will re-check the CI log and update the patch
if any job fails after approval.
```

## #3293 Canonicalizer Draft PR

Current state:

- Draft by design.
- Waiting for maintainer direction on the optional sidecar approach for #2744.
- `pre-commit.ci - pr` passes.
- gem5 `CI Tests` is `action_required`, expected for an unapproved/draft PR.

Do not comment again while:

- #2744 has no maintainer response,
- the PR is still draft,
- there is no request to change naming scope or utility location.

Consider one short follow-up only if:

- maintainers respond positively to the sidecar direction,
- maintainers request that the PR be marked ready,
- the issue remains quiet for several days and a single direction-check would
  help decide whether to close/keep the draft.

Draft follow-up if direction is needed later:

```text
Checking whether the optional sidecar-tool direction is useful as a first step
for #2744. I kept it draft and avoided changing default stats output. If this
is not the direction maintainers want, I can close the draft or reshape it
before asking for full review.
```

## #3241 Review Support

Current state:

- Comment already posted with focused test gaps.
- Do not take over the contributor's implementation.

Do not comment again while:

- author/maintainers have not responded,
- only existing clang-format failure remains,
- no one has asked for a patch or follow-up PR.

Consider one short follow-up only if:

- the author asks for test help,
- maintainers ask for a focused test PR,
- the implementation changes and one of the original concerns is resolved or
  invalidated.

## Daily Check Routine

Run:

```sh
./34_refresh_gem5_status.sh
```

Then update only these local files if something changed:

- `19_open_pr_status.md`
- `33_current_waiting_state.md`
- `20_oss_evidence_package.md` if the change matters for application evidence

Post to GitHub only if the rules above say a comment is useful.
