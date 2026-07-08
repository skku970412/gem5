# Manual GitHub updates

Last refreshed: 2026-07-08 11:40 UTC

Use this when `gh` is unavailable or unauthenticated. Current environment
state:

- `gh` is not installed.
- No `GH_TOKEN` / `GITHUB_TOKEN` is available.
- Public GitHub API access may be rate-limited.
- Git push/fetch can still work through the configured `git` remotes; this
  limitation is only for editing GitHub PR metadata and posting comments via
  the GitHub API.

If a token becomes available, the safer scripted path is:

```sh
./43_apply_github_pr_updates.sh --dry-run
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply
```

For only #3291:

```sh
./43_apply_github_pr_updates.sh --dry-run --only 3291 --post-comments
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply --only 3291 --post-comments
```

Only add `--post-comments` if you intentionally want to post the prepared
review-response comments:

```sh
GITHUB_TOKEN=<token> ./43_apply_github_pr_updates.sh --apply --post-comments
```

Without `--post-comments`, the script only updates:

- #3291 body from `03_pr1_body.md`.
- #3292 title/body from `13_chi_macos_case_pr_body.md`.

## Priority 1: update PR #3291 body

PR: https://github.com/gem5/gem5/pull/3291

Why:

- The code now parses integer-looking values as `int`, not float.
- The remote PR body still describes the older float-only behavior.
- The latest local `build/NULL/gem5.opt` pyunit runner passed, but the default
  `ALL` build did not complete due a local protobuf mismatch. The remote body
  should not keep claiming `scons build/ALL/gem5.opt -j4` passed for the
  latest commit.

Action:

1. Prefer the script above if `GITHUB_TOKEN` is available.
2. Otherwise open #3291 in the browser.
3. Edit the PR body.
4. Replace the body with `03_pr1_body.md`.
5. Optionally post the general response from `41_pr3291_review_response.md`.

Do not:

- Do not add CHI/macOS fix details to #3291 beyond a brief note if asked.
- Do not claim the default `ALL` build passed on commit `240b6f0961`.
- Do not reopen/reset review threads unnecessarily.

Current local verification to mention:

```sh
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v
python3 -m unittest discover -s tests/pyunit -p 'pyunit_stats_txt.py' -v
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  tests/pyunit/stats/stats_txt.py \
  tests/pyunit/stats/pyunit_stats_txt.py \
  tests/pyunit/stats/fixtures/edge_values.txt
git diff --check origin/develop...HEAD
git diff --check
./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
```

## Priority 2: update PR #3292 title/body/comment

PR: https://github.com/gem5/gem5/pull/3292

Why:

- The branch was force-pushed from the directory-rename fix to a smaller
  no-directory-rename fix.
- The remote PR title/body still describe renaming
  `src/mem/ruby/protocol/chi` to `src/mem/ruby/protocol/CHI`.
- Maintainer feedback specifically objected to the directory rename, so the
  remote description must make clear that the current patch avoids that cost.

Action:

1. Prefer the script above if `GITHUB_TOKEN` is available.
2. Otherwise open #3292 in the browser.
3. Change title to:

```text
mem-ruby: avoid CHI generated include case mismatch
```

4. Replace the PR body with `13_chi_macos_case_pr_body.md`.
5. Post this comment:

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
- `scons build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o build/ALL/mem/ruby/protocol/chi/generic/CBusy.o build/ALL/python/_m5/param_CHIGenericController.o -j4`

If this still feels too invasive relative to the CI-only failure, I am fine
closing it and keeping #3291 scoped to parser work.
```

Do not:

- Do not argue for the old directory rename.
- Do not mix #3291 parser work into #3292.
- Do not expand the CHI patch beyond the include-path/case issue unless a
  maintainer asks.

## Priority 3: wait

After the manual updates:

- Wait for #3291 maintainer review from BobbyRBruce / Erin Le.
- Wait for #3292 maintainer response to the no-directory-rename patch.
- Keep #3293 draft until maintainers give direction on #2744.
- Do not take over #3241; keep it review/test support only.
