# Stats

These tests ensure the stats are output correctly.

1. "test_hdf5" - Test hdf5 output. Runs a simulation and ensures the hdf5
   output exists.
2. "test_pystat_output" - Tests that Python-defined stats are output
   correctly.
3. "test_stats_reset" - Tests that selected statistics reset after
   `m5.stats.reset()` is called.

```bash
./main.py run gem5/stats --length=[length]
```

## Stats reset validation

The reset validation test checks `m5.stats.reset()` without relying on fixed
reference stats files. It runs one gem5 invocation, dumps stats before reset,
calls `m5.stats.reset()`, runs briefly again, and dumps stats after reset. The
test then compares the two dumps from that same run.

Generating both dumps in one invocation avoids depending on test execution
order or a reference file produced by a separate test. This matters because the
test runner may schedule tests independently.

The reset test intentionally checks a narrow set of resettable stats instead of
diffing the whole `stats.txt` file. Some stats describe lifetime, constant, or
host-side state and are not expected to reset in the same way. Examples include
`finalTick`, `simFreq`, `hostSeconds`, `hostTickRate`, and `hostMemory`.

Zero-valued stats may be omitted from text stats output. When adding reset
checks, handle an absent after-reset stat only when absence is expected to mean
zero for that stat, and document that choice in the verifier.

To add more reset coverage:

1. Extend the config in `configs/stats_reset_check.py` or add a similarly
   small config that does not need external downloads.
2. Dump stats before reset, call `m5.stats.reset()`, run a deterministic short
   interval, and dump stats after reset in the same invocation.
3. Add the smallest set of resettable stats to the verifier.
4. Document any lifetime, constant, host-side, or omitted-zero behavior.
5. Keep failure messages actionable by reporting the stat name, before value,
   after value, and expected reset behavior.

To run only the reset validation suite:

```bash
./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-NULL-x86_64-opt
```
