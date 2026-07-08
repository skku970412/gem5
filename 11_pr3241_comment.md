I took a look from the testing/edge-case side. The PR is small, and the `name::subname` direction matches the live power-modeling use case in #3235, but I think a few cases need tests before this is safe to merge:

- If a requested `name::subname` is not found, `getStatValue()` currently falls back to `total()`. That means a typo in a subname can silently evaluate to an aggregate value instead of failing.
- A scalar stat requested as `scalar_stat::subname` currently returns the scalar value. I think that should fail clearly, since `::subname` was explicit.
- The implementation only casts multi-value stats to `FormulaInfo`, while `VectorInfo` also has `subnames`, `result()`, and `total()`. If FormulaInfo-only support is intentional, it would be good to document/test that limitation; otherwise this probably wants to handle `VectorInfo` generally.
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
