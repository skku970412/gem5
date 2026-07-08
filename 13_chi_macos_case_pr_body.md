Summary:
- Keep the hand-written CHI source directory as `src/mem/ruby/protocol/chi`.
- Include SLICC-generated CHI headers by basename from CHI-specific sources.
- Add the generated CHI protocol directory to the CHI build include path.
- Leave simulator behavior, SLICC protocol naming, and default stats work
  unchanged.

Motivation:
- The SLICC protocol is named `CHI`, so generated files are emitted under
  `build/.../mem/ruby/protocol/CHI`.
- The hand-written source directory is lower-case `chi`.
- On case-insensitive filesystems such as the default macOS filesystem, source
  mirror paths and generated protocol paths can collide in ways that trigger
  Clang `-Wnonportable-include-path` diagnostics.
- A previous version renamed the source directory, but maintainer feedback
  correctly pointed out that a directory rename has avoidable downstream cost.

Implementation:
- Change CHI-specific includes of generated headers from
  `mem/ruby/protocol/chi/...` to basename includes, for example
  `CHIDataMsg.hh`.
- Add `build/<variant>/mem/ruby/protocol/CHI` to `CPPPATH` in the CHI generic
  SConscript.
- Add the same generated-header include path for CHI TLM sources when
  `BUILD_TLM` is enabled.
- Do not rename directories and do not change generated SLICC output.

Testing:
- [x] `PATH="$HOME/.local/bin:$PATH" scons build/ALL/python/_m5/param_CHIGenericController.o -j4` passed on 2026-07-08.
- [x] `PATH="$HOME/.local/bin:$PATH" scons build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o build/ALL/mem/ruby/protocol/chi/generic/CBusy.o build/ALL/python/_m5/param_CHIGenericController.o -j4` passed on 2026-07-08.
- [x] `PATH="$HOME/.local/bin:$PATH" pre-commit run --files $(git diff --name-only origin/develop...HEAD)` passed on 2026-07-08.
- [x] `git diff --check origin/develop...HEAD` passed on 2026-07-08.

Compatibility:
- No simulator behavior change intended.
- No directory rename.
- No SLICC protocol name change.
- No generated namespace change.

Notes:
- This is a smaller follow-up to maintainer feedback on the original
  directory-rename approach.
- If maintainers still consider this too invasive for the CI-only failure, I am
  fine closing it and keeping the stats parser PR scoped independently.
