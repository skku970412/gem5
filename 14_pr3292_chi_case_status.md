# PR #3292 CHI macOS case fix

PR: https://github.com/gem5/gem5/pull/3292

Branch: `fix-chi-protocol-case`

Commit: `1f32ed40c3 mem-ruby: avoid CHI generated include case mismatch`

Date opened: 2026-07-07

Last refreshed: 2026-07-08 04:41:06 UTC

## Why this exists

PR #3291 is a stats parser PR, but its macOS opt CI hit an unrelated
`-Wnonportable-include-path` failure while compiling CHI Ruby protocol code.

The root cause is that the SLICC protocol name is `CHI`, while the hand-written
source directory is `src/mem/ruby/protocol/chi`. Generated headers are emitted
under `build/.../mem/ruby/protocol/CHI`.

The first #3292 version fixed this by renaming the source directory to `CHI`.
Maintainer feedback pushed back on that approach because a directory rename is
painful for downstream users with private changes. The current version keeps
the source directory lower-case and only changes generated-header include
handling.

## Current changes

- Keep `src/mem/ruby/protocol/chi` unchanged.
- Change CHI-specific includes of SLICC-generated headers to basename includes:
  `CHIDataMsg.hh`, `CHIRequestMsg.hh`, `CHIResponseMsg.hh`,
  `CHIDataType.hh`, `CHIRequestType.hh`, `CHIResponseType.hh`,
  `CHIProtocolInfo.hh`, `Cache_Controller.hh`, and `Memory_Controller.hh`.
- Add `build/<variant>/mem/ruby/protocol/CHI` to `CPPPATH` in
  `src/mem/ruby/protocol/chi/generic/SConscript`.
- Add the same generated CHI include path in
  `src/mem/ruby/protocol/chi/tlm/SConscript` when `BUILD_TLM` is enabled.

Changed files:

- `src/mem/ruby/protocol/chi/generic/CBusy.cc`
- `src/mem/ruby/protocol/chi/generic/CHIGenericController.cc`
- `src/mem/ruby/protocol/chi/generic/CHIGenericController.hh`
- `src/mem/ruby/protocol/chi/generic/SConscript`
- `src/mem/ruby/protocol/chi/tlm/SConscript`
- `src/mem/ruby/protocol/chi/tlm/controller.cc`
- `src/mem/ruby/protocol/chi/tlm/controller.hh`
- `src/mem/ruby/protocol/chi/tlm/utils.hh`

## Verification

```sh
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
```

Passed on 2026-07-08. This is the narrow target that previously failed when
the generated CHI header path was not visible.

```sh
PATH="$HOME/.local/bin:$PATH" scons \
  build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o \
  build/ALL/mem/ruby/protocol/chi/generic/CBusy.o \
  build/ALL/python/_m5/param_CHIGenericController.o -j4
```

Passed on 2026-07-08. This additionally compiles the hand-written CHI generic
C++ sources with the basename generated-header includes.

```sh
git diff --check origin/develop...HEAD
```

Passed on 2026-07-08.

```sh
PATH="$HOME/.local/bin:$PATH" pre-commit run --files \
  $(git diff --name-only origin/develop...HEAD)
```

Passed on 2026-07-08.

## Current status

- Force-pushed to fork on 2026-07-08:
  `70aab4a06f...1f32ed40c3 fix-chi-protocol-case`.
- `git fetch origin pull/3292/head:refs/remotes/origin/pr/3292` confirms PR
  #3292 now points to `1f32ed40c3`.
- Public GitHub check-run API returned no visible check runs for
  `1f32ed40c3` immediately after the force-push.
- Local worktree is clean.
- `gh` is not available in the current environment, so the PR title/body and
  maintainer reply may need to be posted manually from the browser.

## Maintainer response draft

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

## Related links

- PR #3291 CI note:
  https://github.com/gem5/gem5/pull/3291#issuecomment-4900941873
- PR #3291 follow-up link to #3292:
  https://github.com/gem5/gem5/pull/3291#issuecomment-4901203789
- PR #3292 CI/action-required note:
  https://github.com/gem5/gem5/pull/3292#issuecomment-4901804485
- Closed earlier attempt with same root cause:
  https://github.com/gem5/gem5/pull/3286
