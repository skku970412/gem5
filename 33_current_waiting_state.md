# Current waiting state

Last refreshed: 2026-07-08 11:40:00 UTC

Top-level index: `00_gem5_work_index.md`

Single-page dashboard: `40_gem5_contribution_dashboard.md`

This is the concise status snapshot for deciding what to do next.

## External Waits

- #3291 parser PR:
  review comments were addressed and pushed as
  `6e24b3b44a tests: preserve integer stats parser values`; a follow-up
  coverage commit `240b6f0961 tests: cover stats parser malformed boundaries`
  was pushed after rechecking raw/local files and hidden/control characters.
  `pre-commit.ci - pr` passed on `6e24b3b44a`; wait for rerun on
  `240b6f0961`. The public PR page still shows no approving maintainer review
  and still lists BobbyRBruce as awaiting review. The remote PR body is stale
  and should be updated from
  `03_pr1_body.md` when GitHub auth/browser access is available.
- #3292 CHI case-fix PR:
  maintainer objected to the original directory rename. A smaller
  no-directory-rename fix was force-pushed as
  `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`.
  `pre-commit.ci - pr` passed. The PR title/body/comment still need manual
  update from `13_chi_macos_case_pr_body.md` because the remote PR still
  describes the old directory-rename approach.
- #3293 canonicalizer draft PR:
  waiting for maintainer direction on the optional sidecar-tool approach for
  #2744. Keep it draft until direction is clear.
- #3241 runtime stats lookup PR:
  waiting for author/maintainer response. Do not patch unless they ask for
  review/test help.
- Local PR2/PR3 stack:
  rebased on 2026-07-08 so `stats-reset-validator` now sits on latest #3291
  commit `240b6f0961`, and `stats-reset-validation-docs` sits on the updated
  PR2 branch. PR2 now uses the smaller `NULL` target. Fork branches were
  force-with-lease updated.

## Local Branch State

Current branch:

```text
stats-txt-parser-pyunit
```

Current important heads:

```text
#3291 / stats-txt-parser-pyunit: 240b6f0961
#3292 / fix-chi-protocol-case: 1f32ed40c3
PR2 / stats-reset-validator: 33d79e2c2e
PR3 / stats-reset-validation-docs: d176af0239
```

Current PR2/PR3 stack counts:

```text
origin/develop...stats-txt-parser-pyunit: 2 6
stats-txt-parser-pyunit...stats-reset-validator: 0 1
stats-reset-validator...stats-reset-validation-docs: 0 1
```

`origin/develop` advanced to `a61fe05b14`. Do not rebase open PR #3291 just
for this drift unless maintainers request it or CI requires it; rebasing would
force-push a reviewed PR branch.

No local uncommitted changes in `gem5/`.

GitHub metadata update constraint:

```text
GH_TOKEN unset
GITHUB_TOKEN unset
gh not installed
```

Because of this, this shell can update git branches through configured git
remotes but cannot edit GitHub PR bodies or post review-response comments via
the GitHub API.

## Latest Verification

For #3291 review response:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
```

Passed 12 tests.

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
```

Passed.

```sh
git diff --check origin/develop...HEAD
git diff --check
```

Passed.

`./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`
could not be completed with the default local build because
`scons build/ALL/gem5.opt -j4` failed at link with protobuf/absl undefined
references caused by the container's inconsistent protobuf/protoc/header/lib
setup. A separate `build/NULL/gem5.opt` was built with `PROTOC=/bin/false`,
`USE_TEST_OBJECTS=y`, and `HAVE_PROTOBUF=0` for PR2 validation.

For #3292 smaller CHI fix:

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

Passed before the `1f32ed40c3` force-push.

For PR2/PR3 stack maintenance on 2026-07-08:

```sh
git diff --check stats-txt-parser-pyunit...stats-reset-validator
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/gem5/stats/configs/stats_reset_check.py \
  tests/gem5/stats/test_stats_reset.py
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
cd tests && ./main.py list -q --suites | grep -i stats
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
cd tests && ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
git diff --check stats-reset-validator...stats-reset-validation-docs
PATH="$HOME/.local/bin:$PATH" pre-commit run --files tests/gem5/stats/README.md
./36_open_pr2_after_3291.sh
```

Passed where applicable. The reset suite passed twice on
`build/NULL/gem5.opt`, 2 tests per run. `./36_open_pr2_after_3291.sh` fetched the latest
`origin/develop`, detected that #3291 is not merged or cannot be proven merged,
and left branches unchanged. Remote fork heads now point to:

```text
stats-reset-validator: 33d79e2c2e
stats-reset-validation-docs: d176af0239
```

## Ready But Not Opened

- PR2 `stats-reset-validator` is ready as a stacked follow-up, but should not
  be opened against upstream `develop` until #3291 lands or maintainers approve
  stacked PRs. It is now rebased on current #3291 and pushed to the fork.
- PR3 `stats-reset-validation-docs` is ready as a docs follow-up, but should
  not be opened until PR2 lands or maintainers approve the full stack. It is
  now rebased on current PR2 and pushed to the fork.

## Do Not Do Yet

- Do not merge CHI changes into #3291.
- Do not mark #3293 ready while #2744 direction is still unconfirmed.
- Do not take over #3241.
- Do not open PR2/PR3 against `develop` while their diffs include earlier stack
  commits.

## Next Useful Action

1. Monitor #3291 CI/review on `240b6f0961`.
2. If browser/GitHub auth is available, update #3291 body from
   `03_pr1_body.md` and optionally post the #3291 review response from
   `41_pr3291_review_response.md`.
3. If browser/GitHub auth is available, update #3292 title/body from
   `13_chi_macos_case_pr_body.md` and use the response draft in
   `40_gem5_contribution_dashboard.md`.
4. Use `42_manual_github_updates.md` as the copy/paste checklist for both
   manual GitHub updates.
5. If no external state changes, do not post more comments; follow
   `35_maintainer_followup_policy.md`.
