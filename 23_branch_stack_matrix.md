# gem5 branch stack matrix

Last refreshed: 2026-07-08 11:40 UTC

## Stats reliability stack

Base order:

```text
develop
  -> stats-txt-parser-pyunit
    -> stats-reset-validator
      -> stats-reset-validation-docs
```

Current commits:

```text
stats-txt-parser-pyunit:     240b6f0961 tests: cover stats parser malformed boundaries
stats-reset-validator:       33d79e2c2e tests: add stats reset validation
stats-reset-validation-docs: d176af0239 tests: document stats reset validation
```

Ancestor checks:

- `stats-txt-parser-pyunit` is an ancestor of `stats-reset-validator`.
- `stats-reset-validator` is an ancestor of `stats-reset-validation-docs`.

Stack counts:

```text
origin/develop...stats-txt-parser-pyunit:                 2 6
stats-txt-parser-pyunit...stats-reset-validator:       0 1
stats-reset-validator...stats-reset-validation-docs:   0 1
```

`origin/develop` advanced to:

```text
a61fe05b14 cpu-o3: add LeastLoaded IQ insertion policy (#3115)
d47228da49 scons: Fix compiler detection when CXX is clang++ (#3249)
```

Do not rebase open PR #3291 solely for this drift unless maintainers request it
or CI requires it.

Parser branch diff against `origin/develop`:

```text
10 files changed under tests/pyunit/stats
```

Reset-validator diff against `stats-txt-parser-pyunit`:

```text
tests/gem5/stats/configs/stats_reset_check.py |  50 ++++++++
tests/gem5/stats/test_stats_reset.py          | 162 ++++++++++++++++++++++++++
2 files changed, 212 insertions(+)
```

Docs diff against `stats-reset-validator`:

```text
tests/gem5/stats/README.md | 45 ++++++++++++++++++++++++++++++++++++++++++---
1 file changed, 42 insertions(+), 3 deletions(-)
```

## Separate PR branches

CHI case-fix branch:

- Branch: `fix-chi-protocol-case`
- Base: `develop`
- PR: https://github.com/gem5/gem5/pull/3292
- Current pushed commit:
  `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`
- Diff: no-directory-rename CHI generated-header include/path fix only.

Stats canonicalizer branch:

- Branch: `stats-name-canonicalizer`
- Base: `develop`
- Draft PR: https://github.com/gem5/gem5/pull/3293
- Keep draft until maintainers decide #2744 direction.

## Latest local hygiene checks

Passed on 2026-07-08:

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

`./36_open_pr2_after_3291.sh` fetched `origin/develop`, detected that #3291 is
not merged or cannot be proven merged, and left branches unchanged.

Local build note:

```sh
scons build/ALL/gem5.opt -j4
```

failed at link in this container due protobuf/protoc/header/library mismatch
and protobuf/absl undefined references. Local validation used
`PROTOC=/bin/false` to build `build/NULL/gem5.opt` with `HAVE_PROTOBUF=0`.

## Open-order guidance

1. Keep #3291 as the parser PR.
2. Do not open `stats-reset-validator` until #3291 is accepted or maintainers
   explicitly approve a stacked PR.
3. Do not open `stats-reset-validation-docs` until the reset-validator PR is
   accepted or maintainers explicitly approve the full stack.
4. Keep #3292 separate from all stats work.
5. Keep #3293 draft until maintainers agree with the optional sidecar
   canonicalizer direction.
