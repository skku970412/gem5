# gem5 contribution dashboard

Last updated: 2026-07-08 11:40 UTC

This is the single-page status report for continuing the gem5 contribution
work. Use this first, then open the detailed files linked from each section.

## Current priority

1. PR #3291 review comments have been addressed and pushed at `6e24b3b44a`;
   parser-boundary coverage was added at `240b6f0961`.
2. Remote #3291 body still describes the old float-only parser behavior and
   still claims the older `ALL/gem5.opt` validation. Replace it with
   `03_pr1_body.md`.
3. There is no GitHub API auth in this shell (`GH_TOKEN`/`GITHUB_TOKEN` are
   unset and `gh` is not installed), so update stale PR metadata from the
   browser or rerun `43_apply_github_pr_updates.sh` after exporting a token.
4. Remote #3292 title/body still describe the old directory-rename approach.
5. Monitor #3291/#3292 review and CI after the metadata updates.
6. Do not rebase #3291 solely because `origin/develop` is now `2 6` against
   the parser branch; avoid force-pushing reviewed PRs unless required.

## Identity / repo

- Local repo: `gem5/`
- Upstream: `https://github.com/gem5/gem5`
- Fork remote: `git@github.com:skku970412/gem5.git`
- Local git author now configured as:
  - `user.name = 이재욱`
  - `user.email = hg9430@g.skku.edu`
- Main upstream base should be `origin/develop`.

## Open PR summary

| PR | Branch | Purpose | Current status | Next action |
| --- | --- | --- | --- | --- |
| #3291 | `stats-txt-parser-pyunit` | stats.txt multi-dump parser tests | Open; review comments addressed at `6e24b3b44a`; latest head `240b6f0961`; remote PR body is stale. | Update PR body from `03_pr1_body.md`, optionally post `41_pr3291_review_response.md`, then monitor. |
| #3292 | `fix-chi-protocol-case` | CHI include/path case fix for macOS CI | Open; smaller no-directory-rename fix pushed at `1f32ed40c3`; remote title/body are stale. | Update title/body from `13_chi_macos_case_pr_body.md`, post maintainer response, then monitor. |
| #3293 | `stats-name-canonicalizer` | draft optional stats name canonicalizer for #2744 | Draft; no maintainer direction yet. | Keep draft. Do not expand until feedback. |
| #3241 | `review-pr-3241` local only | review/test support for another contributor's stats lookup PR | Comment/test-gap support only. Do not take over. | Wait unless maintainers ask for help. |

Links:

- #3291: https://github.com/gem5/gem5/pull/3291
- #3292: https://github.com/gem5/gem5/pull/3292
- #3293: https://github.com/gem5/gem5/pull/3293
- #3241: https://github.com/gem5/gem5/pull/3241

## Reviewer / maintainer feedback

### PR #3292

Maintainer feedback on the original directory-rename version:

- They did not see enough benefit for renaming the CHI source directory.
- They were concerned that a directory rename would cause pain for private
  downstream changes.
- They said they are open to reconsidering if the benefits are clearly larger
  than the downsides.

Implication:

- Do not continue with the broad `src/mem/ruby/protocol/chi` -> `CHI` rename
  unless maintainers explicitly request it.
- The better response is a smaller fix that keeps the source tree directory as
  `chi` and only fixes the generated-header include casing problem.

Draft response after the smaller fix is pushed:

```markdown
Thanks for the feedback. I agree the directory rename has a higher downstream
cost than the CI issue justifies, so I force-pushed a smaller version that keeps
`src/mem/ruby/protocol/chi` unchanged.

The new version only avoids spelling SLICC-generated CHI headers through a
source-tree path whose case can differ on macOS. It uses generated-header
basename includes from CHI-specific sources and adds the generated CHI protocol
directory to the local build include path.

Local checks:
- `git diff --check origin/develop...HEAD`
- `pre-commit run --files $(git diff --name-only origin/develop...HEAD)`
- `scons build/ALL/python/_m5/param_CHIGenericController.o -j4`

If this still feels too invasive relative to the CI-only failure, I am fine
closing it and keeping #3291 scoped to parser work.
```

### PR #3291

- Review comments were added on 2026-07-08 and addressed in
  `6e24b3b44a`; additional parser-boundary tests were added in
  `240b6f0961`.
- Parser PR should stay parser-only.
- Do not mix CHI CI fixes into #3291.
- Remote PR body still needs a manual update: it currently says values are
  parsed with Python `float` and lists the old `ALL/gem5.opt` build/pyunit
  runner result. The replacement body is in `03_pr1_body.md`.

### PR #3293

- No maintainer decision observed yet on #2744 direction.
- Keep as draft because canonical stats naming is user-facing.

### PR #3241

- This is another contributor's PR.
- Current role is review/test support only.
- Do not open a competing implementation.

## What I changed so far

### Stats parser work, PR #3291

Built a focused parser utility/test PR for #1644:

- Adds parser logic for multi-dump `stats.txt` output.
- Preserves stat names, including `::` subnames.
- Adds unit fixtures and parser pyunit coverage.
- Keeps simulator behavior unchanged.

Latest review response pushed on 2026-07-08:

- Commit: `6e24b3b44a tests: preserve integer stats parser values`
- Changed integer-looking stat values to parse as `int`, preserving large
  counters/ticks beyond float's 53-bit exact range.
- Kept decimal, scientific notation, `nan`, and `inf` values as `float`.
- Added fixture coverage for `18446744073709551615`.
- Updated new parser/test file copyright holder to
  `Sungkyunkwan University`.
- Follow-up commit: `240b6f0961 tests: cover stats parser malformed boundaries`
  adds missing-value and nested-begin delimiter tests, plus an explicit
  `simTicks` integer-type assertion.

Detailed files:

- `03_pr1_body.md`
- `03_pr1_description.md`
- `05_pr1_adversarial_review.md`
- `25_pr3291_maintainer_summary.md`
- `26_pr3291_final_gate.md`
- `41_pr3291_review_response.md`

### Reset validator/docs follow-up stack

Prepared but should not open until #3291 merges:

- PR2 candidate: reset validation test for `m5.stats.reset()`.
- PR3 candidate: docs for reset validation workflow.

Latest stack maintenance on 2026-07-08:

- Rebased `stats-reset-validator` onto current #3291 commit
  `240b6f0961`.
- Rebased `stats-reset-validation-docs` onto the updated PR2 branch.
- Changed PR2 to the smaller `NULL` target because the reset config uses only
  `ScalarStatTester` and no ISA-specific setup.
- Current PR2 commit:
  `33d79e2c2e tests: add stats reset validation`.
- Current PR3 commit:
  `d176af0239 tests: document stats reset validation`.
- Stack counts are clean:
  `stats-txt-parser-pyunit...stats-reset-validator = 0 1` and
  `stats-reset-validator...stats-reset-validation-docs = 0 1`.
- #3291 is now `2 6` against `origin/develop` after upstream develop advanced
  to `a61fe05b14`; no rebase was performed.
- Force-pushed both candidate branches to the fork with
  `git push --force-with-lease fork stats-reset-validator stats-reset-validation-docs`.

Detailed files:

- `27_pr2_opening_packet.md`
- `28_pr3_opening_packet.md`
- `31_pr2_body_current.md`
- `32_pr3_body_current.md`

### CHI macOS case fix, PR #3292

Original pushed version:

- Renamed `src/mem/ruby/protocol/chi` to `src/mem/ruby/protocol/CHI`.
- Maintainer pushed back because rename cost is high for downstream users.

Current pushed version:

- Removed directory rename.
- Changed generated CHI includes to basenames such as `CHIDataMsg.hh`,
  `CHIRequestMsg.hh`, `Cache_Controller.hh`.
- Added `build/<variant>/mem/ruby/protocol/CHI` to the CHI-specific SCons
  `CPPPATH`.
- Kept source-tree includes such as
  `mem/ruby/protocol/chi/generic/CHIGenericController.hh` unchanged.
- Force-pushed commit:
  `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`.

Changed files in the pushed commit:

- `gem5/src/mem/ruby/protocol/chi/generic/CBusy.cc`
- `gem5/src/mem/ruby/protocol/chi/generic/CHIGenericController.cc`
- `gem5/src/mem/ruby/protocol/chi/generic/CHIGenericController.hh`
- `gem5/src/mem/ruby/protocol/chi/generic/SConscript`
- `gem5/src/mem/ruby/protocol/chi/tlm/SConscript`
- `gem5/src/mem/ruby/protocol/chi/tlm/controller.cc`
- `gem5/src/mem/ruby/protocol/chi/tlm/controller.hh`
- `gem5/src/mem/ruby/protocol/chi/tlm/utils.hh`

## Verification facts

Commands passed on the pushed commit:

```sh
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
```

```sh
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o \
  build/ALL/mem/ruby/protocol/chi/generic/CBusy.o \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
```

```sh
git diff --check origin/develop...HEAD
```

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  $(git diff --name-only origin/develop...HEAD)
```

Remote verification:

```sh
git ls-remote fork refs/heads/fix-chi-protocol-case
git fetch origin pull/3292/head:refs/remotes/origin/pr/3292
git rev-parse --short origin/pr/3292
```

Both fork and PR ref point to `1f32ed40c3`.

Public GitHub check-run API returned no visible check runs for `1f32ed40c3`
immediately after the force-push.

For #3291 commit `240b6f0961`, the following passed locally:

```sh
python3 -m py_compile tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
python3 -m unittest discover -s tests/pyunit -p 'pyunit_stats_txt.py' -v
```

Both unittest invocations passed 12 tests.

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
```

Hidden/control character scan for tracked source and fixture files under
`tests/pyunit/stats`: passed.

```sh
git diff --check origin/develop...HEAD
git diff --check
```

```sh
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

Result: passed, 12 tests.

`./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
could not be completed with the default local build because
`scons build/ALL/gem5.opt -j4` failed at link with protobuf/absl undefined
references. The container has inconsistent protobuf pieces (`pkg-config`
reports protobuf 3.12.4 while `protoc` and headers are 25.3). A separate
`build/NULL/gem5.opt` was built for PR2 validation with `PROTOC=/bin/false`,
`USE_TEST_OBJECTS=y`, and `HAVE_PROTOBUF=0`.

For the PR2/PR3 stack maintenance on 2026-07-08, the following passed:

```sh
git diff --check stats-txt-parser-pyunit...stats-reset-validator
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/gem5/stats/configs/stats_reset_check.py \
  tests/gem5/stats/test_stats_reset.py
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py list -q --suites | grep -i stats-reset
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
git diff --check stats-reset-validator...stats-reset-validation-docs
PATH="$HOME/.local/bin:$PATH" pre-commit run --files tests/gem5/stats/README.md
./36_open_pr2_after_3291.sh
```

The reset suite passed twice on `build/NULL/gem5.opt`, 2 tests per run.

`./36_open_pr2_after_3291.sh` verified the guard path: #3291 is not merged or
cannot be proven merged, so PR2 opening was skipped and branches were left
unchanged.

## Manual GitHub update queue

Detailed checklist: `42_manual_github_updates.md`

Token-based helper:

```sh
./43_apply_github_pr_updates.sh --dry-run
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply
```

Current manual actions:

1. #3291: edit PR body from `03_pr1_body.md`; optionally post
   `41_pr3291_review_response.md`.
2. #3292: change PR title to
   `mem-ruby: avoid CHI generated include case mismatch`, edit body from
   `13_chi_macos_case_pr_body.md`, then post the maintainer response draft.

## Local tooling notes

- `gh` is not available in this environment.
- GitHub comments, PR title edits, and PR body edits requiring auth may need to
  be done manually from the browser unless a token/CLI is provided.
- `34_refresh_gem5_status.sh` and `39_capture_gem5_status_snapshot.sh` now
  fall back to the public GitHub API when `gh` is unavailable. If the
  unauthenticated API is rate-limited, they record the API error instead of
  failing noisily.
- `scons` and `pre-commit` are installed under `~/.local/bin`.
- Use:

```sh
PATH="$HOME/.local/bin:$PATH" <command>
```

## Do not do

- Do not broaden #3292 into unrelated CHI or Ruby refactoring.
- Do not mix #3292 changes into #3291.
- Do not open PR2 reset validator until #3291 parser PR is merged or
  maintainers explicitly request a combined approach.
- Do not take over #3241.

## Next exact action

For PR #3291:

1. Manually update the PR body from `03_pr1_body.md` if GitHub auth/browser
   access is available.
2. Optionally post the response from `41_pr3291_review_response.md`.
3. Monitor #3291 CI/review.

For PR #3292:

1. Manually update the PR title/body from `13_chi_macos_case_pr_body.md`.
2. Post the maintainer response draft from `42_manual_github_updates.md`.
3. Monitor #3292 CI/review.

For the stats work:

1. Keep #3291 unchanged unless maintainers request more changes.
2. Do not open PR2 reset validator until #3291 is merged or maintainers ask for
   a combined path.
