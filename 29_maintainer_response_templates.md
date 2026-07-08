# Maintainer response templates

Last refreshed: 2026-07-07 08:31:32 UTC

Use these as starting points only. Before posting, re-check the PR state with
`gh pr view`/`gh pr checks` and edit out anything stale.

## #3291: parser scope

Thanks for taking a look. I kept this PR limited to the parser utility and its
unit tests so the follow-up reset validator can stay focused on test behavior
rather than parser mechanics.

The parser intentionally preserves stat names exactly as printed, including
`::` substat names, and returns dumps in file order. It does not canonicalize
names or change gem5 output. The follow-up reset test is staged separately so
that this PR remains a small, reviewable test utility change.

If you prefer a different test-helper location, I can move the utility while
keeping the API and fixtures unchanged.

## #3291: unrelated macOS opt failure

The current `macos-compilation (opt)` failure appears unrelated to this parser
PR. This PR only changes files under `tests/pyunit/stats`, while the failing
job stops in the CHI Ruby protocol build due include-path casing.

I opened #3292 as a separate focused fix for that case mismatch so this parser
PR can stay limited to stats parser tests. I can re-check/rebase this PR after
the CHI fix lands or after CI is re-run.

## #3291: queued self-hosted jobs

The remaining pending checks appear to be queued self-hosted jobs rather than
parser failures. The job API showed the pending jobs queued for
`self-hosted`, `linux`, `x64` runners with no runner assigned.

Locally, the parser pyunit tests, gem5 pyunit runner for `tests/pyunit/stats`,
pre-commit on the changed files, `git diff --check`, and a real-output smoke
test against `configs/learning_gem5/part1/simple.py` all pass.

## #3292: CHI case-fix scope

This PR is intentionally limited to matching the CHI protocol directory casing
used by generated include paths on case-sensitive and case-checking builds. It
does not change protocol behavior or SLICC semantics.

I verified the targeted CHI objects and Python parameter object locally:

```sh
scons build/ALL/mem/ruby/protocol/CHI/generic/CHIGenericController.o \
      build/ALL/mem/ruby/protocol/CHI/generic/CBusy.o \
      build/ALL/python/_m5/param_CHIGenericController.o -j4
```

If there is a preferred alternative, such as changing generated include spelling
instead of the source directory case, I can adjust the patch in that direction.

## #3293: draft canonicalizer rationale

I left this PR as draft because #2744 is a user-facing naming discussion. This
prototype is deliberately optional: it reads existing stats/config output and
emits a canonicalized copy or mapping report without changing default gem5
stats output, SimObject naming, or simulator behavior.

The tool only canonicalizes names it can infer from `config.json` and fails on
collisions by default. Ambiguous digit-suffix names are left unchanged unless a
config-backed mapping makes them safe.

If maintainers agree that an optional sidecar tool is the right first step, I
can mark it ready after handling any requested naming or location changes.

## #3293: collision behavior

The canonicalizer fails on old-name to canonical-name collisions by default
because silently merging distinct stats would be misleading for machine
consumers. `--allow-collisions` exists only for explicit exploratory use.

The tests cover collision failure, idempotency, `::` substat preservation, and
names that should remain unchanged.

## PR2 after #3291 merges

Once #3291 lands, I plan to rebase the reset-validator branch onto
`origin/develop` and open it as a separate PR. The intended diff is only:

```text
tests/gem5/stats/configs/stats_reset_check.py
tests/gem5/stats/test_stats_reset.py
```

The validator generates before/reset/after dumps in the same gem5 invocation
and avoids fixed reference stats files. It checks a small set of deterministic
resettable stats first, with documented exclusions for lifetime/constant and
host-side stats.

## PR3 after PR2 merges

After the reset-validator PR lands, I plan to open the docs-only follow-up. The
intended diff is only:

```text
tests/gem5/stats/README.md
```

The docs explain how the reset validator works, why same-invocation dumps are
used, why fixed reference stats are avoided, which stats are excluded, and how
future contributors can extend the validator.

## #3241: test-support stance

I do not want to take over the implementation in #3241. My suggested role is
limited to review/test support if the author or maintainers want it.

The highest-value additions seem to be small tests for missing substats,
malformed `name::subname` expressions, scalar-with-subname lookup, and any
documented limitations around vector stats or `FormulaInfo` handling.

If maintainers prefer, I can prepare a small follow-up test PR after #3241
lands instead of patching the contributor's branch.
