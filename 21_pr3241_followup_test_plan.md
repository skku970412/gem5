# PR #3241 follow-up test plan

PR: https://github.com/gem5/gem5/pull/3241

Issue: https://github.com/gem5/gem5/issues/3235

Last refreshed: 2026-07-07 08:15:11 UTC

## Current state

- Local branch: `review-pr-3241`
- Local branch matches the PR head and `origin/pr/3241` at
  `14397a343b4ea4b613c7d0b5a507b81721923572`.
- Upstream PR is open, mergeable, review required.
- All CI jobs are passing except `clang-format-check`.
- `git diff --check origin/develop...review-pr-3241` passes locally.
- Exact CI clang-format command cannot be reproduced locally because this
  environment has neither `clang-format` nor `git-clang-format` installed.
  The GitHub Actions log reports changed files:
  `src/sim/mathexpr.cc` and `src/sim/power/mathexpr_powermodel.cc`.

## Scope decision

Do not open a competing implementation or test PR right now.

Reason:

- The PR changes only `src/sim/mathexpr.cc` and
  `src/sim/power/mathexpr_powermodel.cc`.
- There is no existing narrow pyunit/gtest harness for
  `MathExprPowerModel::getStatValue()`.
- A meaningful test would need either a small C++ harness around statistics
  registration and `MathExprPowerModel`, or a gem5 system-level config that
  registers a power model and exercises runtime expressions.
- That is no longer a trivial comment-only follow-up and could look like
  taking over the contributor's implementation.

## Highest-value tests if maintainers ask

These should be added by the PR author or as an explicitly requested small
follow-up:

- scalar stat lookup succeeds
- `name::subname` lookup succeeds for a multi-value stat
- missing stat name fails clearly
- missing subname fails clearly instead of returning `total()`
- `scalar_stat::subname` fails clearly
- malformed colon expressions fail clearly:
  - `foo:bar`
  - `foo::`
  - `foo:::bar`
- one-element vector stat with a valid explicit subname is handled intentionally

## Likely test locations

Potential options, from least to most invasive:

- A focused system-level test under `tests/gem5/stats` or
  `tests/gem5/power` if an existing config can attach `MathExprPowerModel`
  without external workloads.
- A C++ unit test under `src/sim` or `src/sim/power` only if there is a clean
  way to construct/register stats and instantiate the power model without
  pulling in a broad simulator harness.
- Documentation-only tests are not sufficient for this API because the risk is
  silent wrong numeric lookup.

## Suggested behavior to verify

For an expression with an explicit subname:

```text
stat.name::subname
```

The lookup should not silently fall back to `total()` when `subname` is absent.
The failure should identify both the base stat name and the missing subname.

For a scalar stat:

```text
scalar.stat::subname
```

The explicit subname should fail clearly rather than returning the scalar value.

For malformed colon syntax:

```text
foo:bar
foo::
foo:::bar
```

The parser or lookup path should fail with an actionable message. Only `::`
should have defined subname semantics.

## Current contribution action

Already completed:

- Posted review/test-support comment:
  https://github.com/gem5/gem5/pull/3241#issuecomment-4901121740
- Rechecked PR head and local diff status on 2026-07-07 08:15 UTC.

Recommended next action:

- Monitor the PR.
- If the author or maintainers ask for help, implement the smallest requested
  test only.
- Keep this separate from #1644 and #2744 stats parser/canonicalizer work.
