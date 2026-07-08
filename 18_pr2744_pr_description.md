Summary:
- Add an optional sidecar utility for canonicalizing names in existing
  `stats.txt` files.
- Use `config.json` SimObjectVector metadata to map legacy paths such as
  `system.cpu0` to canonical paths such as `system.cpu[0]`.
- Emit an optional old-name to canonical-name mapping JSON.
- Add pyunit coverage for vector paths, length-one vectors, `::` substats,
  distribution-style trailing columns, unchanged names, idempotency, and
  collision handling.

Motivation:
- Issue #2744 describes how vector-stat naming special cases make machine
  parsing difficult.
- Changing default text stats output would be a broad user-facing compatibility
  change, so this starts with an optional utility instead.
- This PR is intentionally draft while maintainers decide whether this
  sidecar-tool direction is useful.

Implementation:
- `util/stats_canonicalizer.py` reads an input `stats.txt` and writes a
  canonicalized output file.
- Without `config.json`, the utility preserves names and does not guess from
  digit suffixes.
- With `config.json`, it walks explicit SimObjectVector lists and maps concrete
  paths to bracketed canonical paths.
- `::` substat suffixes are preserved.
- Comments, headers, footers, and non-stat lines are preserved.
- Multiple old names mapping to one canonical name fail by default unless
  `--allow-collisions` is passed.

Testing:
- [x] `git diff --check origin/develop...HEAD` passed.
- [x] `pre-commit run --files $(git diff --name-only origin/develop...HEAD)`
      passed.
- [x] `python3 -m unittest discover -s tests/pyunit/util -p 'pyunit_stats_canonicalizer.py' -v`
      passed, 10 tests.
- [x] `./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/util`
      passed, 28 tests.
- [x] CLI smoke test verified output generation, mapping JSON, idempotency, and
      collision failure behavior.
- [x] Real-output smoke test with `configs/learning_gem5/part1/simple.py`
      verified `stats.txt`/`config.json` canonicalization and idempotency.
      The latest run produced 609 mapping entries and changed two names:
      `system.cpu.interrupts.clk_domain.clock` and
      `system.cpu.workload.numSyscalls`.

Compatibility:
- Default gem5 stats output is unchanged.
- Simulator behavior is unchanged.
- SimObject naming is unchanged.
- Ambiguous digit-suffix names are not guessed from `stats.txt` alone.

Follow-up:
- If this direction is accepted, a later PR can discuss whether an opt-in stats
  visitor mode should emit canonical names directly.
