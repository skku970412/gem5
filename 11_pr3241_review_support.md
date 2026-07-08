# gem5 PR #3241 review/test support

PR: https://github.com/gem5/gem5/pull/3241

Issue: https://github.com/gem5/gem5/issues/3235

Date checked: 2026-07-07 08:15 UTC

## Scope

This is review/test support only. Do not take over the implementation or open a competing PR unless maintainers ask for a small follow-up.

PR #3241 adds runtime lookup of single values from multi-value stats for `MathExprPowerModel` expressions, using `name::subname` syntax.

Changed files:

- `src/sim/mathexpr.cc`
- `src/sim/power/mathexpr_powermodel.cc`

## Current upstream PR state

- State: open
- Base: `develop`
- Head: `HugoSipearl:new-feature`
- Mergeable: yes
- Review decision: review required
- Comments/reviews: no maintainer/author response after the posted
  review-support comment
- CI: all listed jobs passed except `clang-format-check`

## Local checkout

Commands run:

```sh
git fetch origin +refs/pull/3241/head:refs/remotes/origin/pr/3241
git switch review-pr-3241
git status --short --branch
```

Result:

```text
## review-pr-3241
```

The local worktree was clean. The local branch and `origin/pr/3241` both point
to PR head `14397a343b4ea4b613c7d0b5a507b81721923572`.

## Local verification

```sh
git fetch origin develop
git diff --check origin/develop...HEAD
```

Result: passed.

```sh
pre-commit run --files src/sim/mathexpr.cc src/sim/power/mathexpr_powermodel.cc
```

Result: passed locally.

```sh
python3 util/run-git-clang-format.py --verbose --ci-pr-base-commit 79800f90a1c93139f102cd0098bcd150cd0af6bb
```

Result: could not reproduce the exact CI formatting output locally because
`git-clang-format` is not installed:

```text
ERROR: Command 'git-clang-format' not found
```

This environment also lacks `clang-format`, so the GitHub Actions
`clang-format-check` failure remains the authoritative formatting evidence.
The CI log shows `git-clang-format --style=file --commit=79800f90...` returned
1 and listed:

```text
src/sim/mathexpr.cc
src/sim/power/mathexpr_powermodel.cc
```

```sh
scons build/ALL/gem5.opt -j4
```

Result: interrupted after a long broad rebuild. The changed files had compiled before interruption, including:

```text
src/sim/mathexpr.cc -> ALL/sim/mathexpr.o
src/sim/power/mathexpr_powermodel.cc -> ALL/sim/power/mathexpr_powermodel.o
```

The build was stopped because it continued compiling unrelated ALL targets. Treat this as partial compile evidence, not a full build pass.

## Review findings

### 1. Missing `name::subname` silently falls back to `total()`

In `src/sim/power/mathexpr_powermodel.cc`, the new lookup path iterates subnames and returns `fi->total()` when the requested subname is not found.

Relevant code:

```cpp
for (size_t i = 0; i < fi->subnames.size(); i++){
    if (fi->subnames[i] == subName)return results[i];

}
return fi->total();
```

Risk: a typo such as `system.cpu.overallAccesses::readTypo` can silently evaluate to the aggregate total instead of failing. For live power modeling, that is a false-positive risk because the model appears valid while using the wrong value.

Suggested behavior: if a `::subname` was explicitly requested and it is not found, fail clearly with the stat name and subname.

### 2. `ScalarInfo` ignores a requested subname

The current `ScalarInfo` path returns the scalar value even when the expression includes `scalar_stat::subname`.

Relevant code:

```cpp
auto si = dynamic_cast<const ScalarInfo *>(info);
if (si)
    return si->value();
```

Risk: malformed or mistaken expressions can silently pass. A scalar stat with `::subname` should probably fail clearly.

### 3. Only `FormulaInfo` multi-value stats are handled

The PR casts to `FormulaInfo`, but gem5 also has `VectorInfo` with `subnames`, `result()`, and `total()` in `src/base/stats/info.hh`.

Relevant API:

```cpp
class VectorInfo : public Info
{
  public:
    std::vector<std::string> subnames;
    virtual const VResult &result() const = 0;
    virtual Result total() const = 0;
};

class FormulaInfo : public VectorInfo
```

Risk: issue #3235 asks for lookup from multi-value stats using `name::subname`; if the implementation is intentionally formula-only, that limitation should be documented and tested. Otherwise, it should likely support `VectorInfo` generally.

### 4. One-element vector/formula subnames are skipped

The current subname lookup only runs when `fi->subnames.size() >= 2`.

Risk: a one-element multi-value stat with a valid subname will fall back to total. If `::subname` is explicitly provided, the number of subnames should not decide whether lookup is attempted.

### 5. `MathExpr` now accepts any colon in variable names

`src/sim/mathexpr.cc` now allows `:` in variables:

```cpp
c == '$' || c == '\\' || c == '.' || c == '_' || c == ':'
```

Risk: only `::` has defined lookup semantics downstream. Expressions like `foo:bar`, `foo:::bar`, or `foo::` may parse as variables and then fail unclearly or resolve the wrong base name. Malformed colon syntax should have explicit tests and clear failure behavior.

### 6. Formatting needs cleanup

CI reports `clang-format-check` failure. The changed file has several obvious formatting issues around missing spaces/braces/indentation, for example:

```cpp
if (sepPos != std::string::npos){
...
} else if (name=="clock_period") {
...
if (fi->subnames[i] == subName)return results[i];
```

This is mechanical, but it currently blocks the PR.

## Suggested tests

Focused tests should cover:

- scalar stat lookup succeeds
- `name::subname` lookup succeeds for at least one multi-value stat
- missing stat name fails clearly
- missing subname fails clearly instead of falling back to `total()`
- `scalar_stat::subname` fails clearly
- malformed lookup expressions such as `foo:bar`, `foo::`, and `foo:::bar`
- behavior after `m5.stats.reset()` only if the API is expected to read reset values during a run

The highest-value tests before merge are missing subname, scalar-with-subname, and malformed colon syntax because these are the easiest ways to silently use the wrong power-model input.

## Interaction with issue #1644

This PR is related to #1644 only conceptually. If runtime stat lookup is later used in reset validation or live checks, silent fallback to `total()` would make reset/power-model failures harder to diagnose. No direct dependency should be introduced between the #1644 parser/reset work and this PR.

## Recommended contribution action

Do not open a competing implementation PR.

Recommended action completed: left a concise review/test-support comment on PR
#3241. Offer edge cases and test suggestions, and let the author decide whether
to patch them.

Comment URL:

https://github.com/gem5/gem5/pull/3241#issuecomment-4901121740

## Draft GitHub comment

```markdown
I took a look from the testing/edge-case side. The PR is small, and the `name::subname` direction matches the live power-modeling use case in #3235, but I think a few cases need tests before this is safe to merge:

- If a requested `name::subname` is not found, `getStatValue()` currently falls back to `total()`. That means a typo in a subname can silently evaluate to an aggregate value instead of failing.
- A scalar stat requested as `scalar_stat::subname` currently returns the scalar value. I think that should fail clearly, since `::subname` was explicit.
- The implementation only casts multi-value stats to `FormulaInfo`, while `VectorInfo` also has `subnames`, `result()`, and `total()`. If FormulaInfo-only support is intentional, it would be good to document/test that limitation; otherwise this probably wants to handle VectorInfo generally.
- `fi->subnames.size() >= 2` skips lookup for one-element stats even if a valid subname was explicitly requested.
- `MathExpr` now accepts any `:` in variable names, but only `::` has semantics downstream. Malformed expressions like `foo:bar`, `foo::`, or `foo:::bar` should probably fail with a clear message.

Suggested focused tests:

- scalar lookup succeeds
- `name::subname` lookup succeeds for a multi-value stat
- missing stat name fails clearly
- missing subname fails clearly
- `scalar_stat::subname` fails clearly
- malformed colon syntax fails clearly

Also, the current CI has `clang-format-check` failing, which looks consistent with the formatting around the new branches. I could not reproduce the exact clang-format diff locally because this checkout does not have `git-clang-format`, but the CI failure is the only failing check I see.
```
