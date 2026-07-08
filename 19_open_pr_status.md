# Open gem5 PR status

Last refreshed: 2026-07-08 05:55 UTC

This is a concise status log for open upstream PRs. Re-check GitHub before
posting comments or force-pushing.

## #3291: tests: add stats.txt parser utility

URL: https://github.com/gem5/gem5/pull/3291

State:

- Open.
- 5 commits into `gem5:develop` from `stats-txt-parser-pyunit`.
- Review comments from Copilot and Erin Le have been addressed in
  `6e24b3b44a tests: preserve integer stats parser values`.
- Awaiting requested review from BobbyRBruce and at least one approving review.

Reviewer feedback handled:

- Copilot: avoid float rounding for large integer stats.
  - Fix: integer-looking values parse as `int`.
  - Test: `18446744073709551615` is asserted as an `int`.
- Erin Le: check new file copyright holder.
  - Fix: new parser/test files now use `Sungkyunkwan University`.

Current remote PR body issue:

- The remote PR body still says integer values are parsed with Python `float`.
- It also still lists the older `gem5.opt` pyunit runner as passed.
- Manual action: edit #3291 body from `03_pr1_body.md`.

Latest local verification on `6e24b3b44a`:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
git diff --check origin/develop...HEAD
git diff --check
```

Result: passed.

Remote check observed:

- `pre-commit.ci - pr` passed on `6e24b3b44a`.

Not completed:

- `./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
  could not be completed in the current environment because the existing
  binary was linked against unavailable newer system libraries. A rebuild
  regenerated stale protobuf outputs and progressed, but the full ALL build was
  stopped before completion because it was broader than this parser-only review
  response.

Next action:

- Update remote PR body from `03_pr1_body.md`.
- Optionally post `41_pr3291_review_response.md`.
- Then wait.

## #3292: mem-ruby CHI include/path case fix

URL: https://github.com/gem5/gem5/pull/3292

State:

- Open.
- 1 commit into `gem5:develop` from `fix-chi-protocol-case`.
- Current pushed commit:
  `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`.
- Maintainer `powerjg` objected to the original directory rename because it
  would cause downstream pain.
- The current branch is no longer a directory rename; it keeps
  `src/mem/ruby/protocol/chi` unchanged and fixes generated-header include
  casing/path locally.

Current remote PR body issue:

- The remote PR title still says:
  `mem-ruby: match CHI protocol directory case`.
- The remote PR body still describes renaming
  `src/mem/ruby/protocol/chi` to `src/mem/ruby/protocol/CHI`.
- Manual action: update title/body from `13_chi_macos_case_pr_body.md`, then
  post the response in `42_manual_github_updates.md`.

Latest local verification on `1f32ed40c3`:

```sh
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o \
  build/ALL/mem/ruby/protocol/chi/generic/CBusy.o \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  $(git diff --name-only origin/develop...HEAD)
git diff --check origin/develop...HEAD
```

Result: passed.

Next action:

- Update stale remote title/body/comment manually.
- Wait for maintainers to decide whether the smaller no-directory-rename fix is
  worth merging.

## #3293: util: add experimental stats name canonicalizer

URL: https://github.com/gem5/gem5/pull/3293

State:

- Draft.
- 1 commit into `gem5:develop` from `stats-name-canonicalizer`.
- No reviews shown in the latest web check.
- Label: `util`.

Assessment:

- Keep draft until maintainers give direction on #2744.
- Do not expand the tool or mark ready unless maintainers accept the optional
  sidecar-tool approach.

## #3241: stats runtime lookup review support

URL: https://github.com/gem5/gem5/pull/3241

State:

- Open.
- Belongs to another contributor.
- 2 commits into `gem5:develop` from `HugoSipearl:new-feature`.
- `powerjg` approved the PR on 2026-07-07.
- Erin Le asked the author on 2026-07-08 about pushing a formatting commit for
  the failing clang-format check.

Our role:

- Review/test support only.
- Comment already posted with focused test-gap concerns around `name::subname`,
  malformed colon syntax, scalar-vs-subname behavior, missing names/subnames,
  and `VectorInfo`/`FormulaInfo` behavior.
- Do not take over or open a competing implementation unless maintainers ask.

## Immediate next actions

1. Manual update #3291 PR body from `03_pr1_body.md`.
2. Manual update #3292 title/body/comment from
   `13_chi_macos_case_pr_body.md` and `42_manual_github_updates.md`.
3. Wait on #3291/#3292 reviews.
4. Keep #3293 draft.
5. Do not patch #3241 unless requested.
