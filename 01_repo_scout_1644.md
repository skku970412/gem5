# Repo Scout: gem5 #1644 Stats Reset Validation

Checked on 2026-07-07 against upstream `gem5/gem5` `develop`.

Local checkout:

- Path: `/home/work/llama_young/for____what/gem5`
- Branch: `develop`
- HEAD: `2dcdb85166` (`2026-07-06 base: Fix ldMin/ldMax not updated in handleLoadableSegment (#3218)`)
- Issue state checked: `#1644` is open, has no assignee, and has no linked branch or PR.

## What #1644 Needs

Issue `#1644` asks for tests proving that stats reset when `m5.stats.reset()` is called. The issue suggests this shape:

1. Run a config for some ticks.
2. Dump stats.
3. Reset stats.
4. Run briefly.
5. Dump stats again.
6. Compare resettable stats from the two dumps.

The issue also says fixed reference stats files are awkward because runner ordering is not guaranteed. The practical implication is that a reset validator should generate before/after dumps inside the same test invocation.

## Test Layout

Python unit tests:

- Actual unit test files live under `tests/pyunit`.
- `tests/run_pyunit.py` discovers files matching `pyunit*.py`.
- `tests/gem5/pyunit/test_run.py` wraps `tests/run_pyunit.py` as a quick system-level suite named `pyunit-tests-ALL-x86_64-opt`.
- `TESTING.md` says Python unit tests are under `tests/gem5/pyunit`, but the current tree has the real pyunit files under `tests/pyunit` and only the TestLib wrapper under `tests/gem5/pyunit`.

System-level tests:

- System-level TestLib suites live under `tests/gem5`.
- They are declared with `gem5_verify_config(...)`.
- Test outputs are written to a TestLib temp directory via gem5 `-d <tempdir> -re --silent-redirect`.
- Common verifiers live in `tests/gem5/verifier.py`.
- `constants.gem5_simulation_stats` is `stats.txt`.

Relevant existing suites:

- `tests/gem5/stats/test_pystat_output.py`
- `tests/gem5/stats/test_hdf5.py`
- `tests/gem5/pyunit/test_run.py`
- `tests/gem5/se_mode/hello_se/test_hello_se.py`
- `tests/gem5/m5_util/test_exit.py`

## Existing Stats Tests

`tests/gem5/stats` already exists and is the best system-level home for future stats reset validation.

Current stats tests include:

- `pystat-scaler-int-test`
- `pystat-scaler-int-zero-test`
- `pystat-scaler-int-negative-test`
- `pystat-scaler-float-test`
- `pystat_vector_test`
- `pystat_vector_with_subnames_test`
- `pystat_vector_with_subdescs_test`
- `pystat_vector2d_test`
- `pystat-sparsehist-test`
- `simstat-simobjectvector-test`
- `hdf5_test`

These tests currently mostly check that configured stats can be emitted or that HDF5 output exists. They do not validate `m5.stats.reset()` behavior.

## Stats Dump Format

The text stats output is implemented in `src/base/stats/text.cc`.

Dump delimiters:

```text
---------- Begin Simulation Statistics ----------
---------- Begin Simulation Statistics : <message> ----------
---------- End Simulation Statistics   ----------
```

Text output defaults are configured in `src/python/m5/stats/__init__.py`:

- `desc=True`
- `spaces=True`

Stat lines generally look like:

```text
stat.name                                  12345 # optional description
stat.with::subname                         0.25 # optional description
```

Important parser implications:

- Preserve names exactly.
- Do not split or normalize `::`.
- Treat the first token after the stat name as the value.
- Ignore descriptions after the value.
- Ignore begin/end delimiter lines.
- Ignore blank/comment-only lines.
- Support `nan`; text output prints `nan` for NaN values.
- Values from generated fixtures should cover integers, floats, negative values, zero, and scientific notation even if gem5 fixed-format output usually avoids exponent notation.
- Zero-valued stats may be omitted when flags/prereqs suppress output.

## Current `m5.stats.dump()` / `reset()` Usage

Found Python use sites include:

- `tests/gem5/processor_switch_tests/configs/cross-product-switch-afterboot.py`
- `tests/gem5/multisim/configs/x86-processor-switch.py`
- `util/disk-image-validator/disk-image-validate.py`
- `configs/common/Simulation.py`
- `configs/example/apu_se.py`
- `configs/example/gem5_library/x86-*-benchmarks.py`
- `src/python/gem5/simulate/exit_event_generators.py`
- `src/python/gem5/simulate/exit_handler.py`

The processor-switch configs already demonstrate calling `m5.stats.dump()` followed by `m5.stats.reset()` from event handlers, but they do not parse `stats.txt` to verify reset behavior.

## Smallest Reliable Target For Reset Test

Best initial target for PR 2:

- Place the suite under `tests/gem5/stats`.
- Use a tiny SE-mode workload with `AtomicSimpleCPU`, `NoCache`, and `SingleChannelDDR3_1600`, matching existing simple stats/hello patterns.
- Prefer `ALL` ISA if the config can parameterize ISA; otherwise start with one deterministic ISA such as X86 or ARM.
- Avoid FS boot, KVM, disk images, checkpoints, and external downloads beyond existing small hello/m5 resources.
- Generate both dumps in the same gem5 run.
- Parse the resulting `stats.txt` from TestLib's temp directory with the PR 1 parser.

The first checked stats should be intentionally narrow, for example:

- `simInsts`
- `simOps`
- `simTicks` or a selected CPU stat only after checking actual output from the chosen config

Do not blindly compare all stats. Exclude or separately document lifetime/constant stats such as `simFreq`, `finalTick`, and host-runtime-style values.

## Parser Location Recommendation

Recommended for PR 1:

- Add parser under `tests/pyunit/stats/stats_txt.py`.
- Add unit tests under `tests/pyunit/stats/pyunit_stats_txt.py`.
- Add fixtures under `tests/pyunit/stats/fixtures/`.

Why:

- The parser is pure Python and should be tested without running a simulation.
- It keeps PR 1 non-invasive and avoids simulator source changes.
- `tests/run_pyunit.py` already discovers `pyunit*.py`.
- Future TestLib verifiers run from the `tests` tree and can import `pyunit.stats.stats_txt` if needed.

Alternatives:

- `tests/gem5/stats`: good for system-level tests, but adding importable helpers there risks confusion with `gem5.stats`.
- `tests/gem5/stats_parser.py`: reasonable for TestLib helpers, but harder to test from current pyunit layout without path tricks.
- `src/python/m5/stats`: importable and clean, but it exposes the parser as simulator Python API rather than a test helper.
- `util`: possible, but broader and less clearly tied to #1644's test infrastructure goal.

## Proposed PR Stack

### PR 1: parser utility

Purpose:

- Add a small parser for multi-dump `stats.txt` files.
- Include fixture-based Python unit tests.
- No simulator behavior change.

Candidate files:

- Add `tests/pyunit/stats/__init__.py`
- Add `tests/pyunit/stats/stats_txt.py`
- Add `tests/pyunit/stats/pyunit_stats_txt.py`
- Add fixtures under `tests/pyunit/stats/fixtures/`

Tests to imitate:

- `tests/pyunit/util/pyunit_convert_check.py`
- `tests/pyunit/pystats/pyunit_pystats.py`
- `tests/run_pyunit.py`

Minimum commands:

```sh
scons build/ALL/gem5.opt -j$(nproc)
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
./build/ALL/gem5.opt tests/run_pyunit.py
git diff --check
pre-commit run --files tests/pyunit/stats/__init__.py tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py
```

If `build/ALL/gem5.opt` is unavailable, build it first with:

```sh
scons build/ALL/gem5.opt -j$(nproc)
```

### PR 2: reset validator

Purpose:

- Add a quick stats reset validation test that generates before/after dumps in the same invocation.
- Parse the resulting `stats.txt`.
- Compare a narrow set of resettable stats.

Candidate files:

- Add `tests/gem5/stats/configs/stats_reset_check.py`
- Add `tests/gem5/stats/test_stats_reset.py`
- Possibly add a stats verifier class in `tests/gem5/verifier.py` or keep verifier logic local to `tests/gem5/stats/test_stats_reset.py`.
- Possibly update `tests/gem5/stats/README.md`.

Tests to imitate:

- `tests/gem5/stats/test_pystat_output.py`
- `tests/gem5/m5_util/test_exit.py`
- `tests/gem5/se_mode/hello_se/test_hello_se.py`
- `tests/gem5/processor_switch_tests/configs/cross-product-switch-afterboot.py` for dump/reset event handling

Minimum commands:

```sh
scons build/ALL/gem5.opt -j$(nproc)
cd tests && ./main.py list -q --suites | grep -i stats
cd tests && ./main.py run --skip-build --uid <new-stats-reset-suite-uid>
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
git diff --check
pre-commit run --files <changed files>
```

### PR 3: docs

Purpose:

- Document reset validation design and extension guidance.
- Explain why fixed reference stats files are avoided.
- Explain lifetime/constant allowlists and zero-stat omission.

Candidate files:

- Modify `tests/gem5/stats/README.md`
- Possibly add or update docs under `docs/` only if there is an existing stats testing page to extend.

Minimum commands:

```sh
git diff --check
pre-commit run --files tests/gem5/stats/README.md
```

## Risks And Avoidance

- Import path confusion between `tests/gem5` and `src/python/gem5`: keep PR 1 parser under `tests/pyunit/stats`, not `tests/gem5/stats`.
- Over-comparing stats in PR 2: start with a small checked set and documented exclusions.
- Flaky workload behavior: use a tiny deterministic SE-mode workload, not FS boot or KVM.
- Reference-file ordering problem: generate before/after dumps in one run.
- Zero-valued stat omission: document absence handling; treat absence as zero only when explicitly intended.
- Generated files in source tree: run tests through TestLib tempdirs and check `git status --short`.
- Build cost: run targeted pyunit first, then stats suite UID, then broader quick checks if feasible.

## Immediate Next Step

Proceed with PR 1 locally:

1. Create a branch from `develop`.
2. Add `tests/pyunit/stats` parser and fixture tests.
3. Build `build/ALL/gem5.opt` if missing.
4. Run targeted pyunit.
5. Fix failures until clean.
6. Prepare PR title/body.
