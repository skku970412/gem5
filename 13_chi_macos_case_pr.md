Title:
mem-ruby: match CHI protocol directory case

Summary:
- Rename `src/mem/ruby/protocol/chi` to `src/mem/ruby/protocol/CHI`.
- Update source includes, SimObject `cxx_header` paths, and the protocol Kconfig include to match the uppercase directory.
- Keep the SLICC protocol name, generated namespace, and simulator behavior unchanged.

Motivation:
- The SLICC protocol is named `CHI`, and generated files are emitted under `build/.../mem/ruby/protocol/CHI`.
- The source directory was lower-case `chi`.
- On case-insensitive filesystems such as the default macOS filesystem, the source mirror path and generated protocol path can collapse to the same physical directory with lower-case canonical spelling.
- Clang then reports `-Wnonportable-include-path` for includes such as `mem/ruby/protocol/CHI/CHIDataMsg.hh`, and the warning is promoted to an error in CI.

Implementation:
- Rename the CHI source directory to match the SLICC protocol name.
- Update references from `mem/ruby/protocol/chi/...` to `mem/ruby/protocol/CHI/...`.
- Update `src/mem/ruby/protocol/Kconfig` from `rsource "chi/Kconfig"` to `rsource "CHI/Kconfig"`.
- Apply minimal style fixes needed because the renamed files are checked by pre-commit.

Testing:
- [x] `pre-commit run --files $(git diff --cached --name-only)` passed before commit.
- [x] `git diff --check origin/develop...HEAD` passed.
- [x] `scons build/ALL/python/_m5/param_CHIGenericController.o -j4` passed.
- [x] `scons build/ALL/mem/ruby/protocol/CHI/generic/CHIGenericController.o build/ALL/mem/ruby/protocol/CHI/generic/CBusy.o build/ALL/python/_m5/param_CHIGenericController.o -j4` passed.

Compatibility:
- No simulator behavior change intended.
- No SLICC protocol name change.
- No generated namespace change.

Notes:
- This is a clean, focused version of the same root-cause fix attempted in closed PR #3286.
- This also matches the unrelated macOS CI failure observed on PR #3291.
