# gem5 issue #2744 design report: canonical stats names

## Recommendation

Choose **A. sidecar canonicalizer/report utility first**.

Do not change default text stats naming in a first contribution. The current
names are assembled across Python SimObject hierarchy code, C++ text stats
printing, and PyStats compatibility helpers. A default naming change would be
user-facing and would likely break scripts, reference stats, and tests that
parse old names.

The first PR should be an optional, conservative tool that reads existing
outputs and emits either:

- a mapping report from current names to proposed canonical names, or
- a rewritten stats file only for mappings proven safe.

Ambiguous cases must fail or be reported as ambiguous by default. A
stats.txt-only tool cannot safely infer every canonical name.

## Issue status

- Issue: https://github.com/gem5/gem5/issues/2744
- State checked: open
- Last updated: 2025-11-11
- Comments checked: no comments returned by `gh issue view --comments`

The issue describes two related problems:

- `SimObjectVector` length 1 uses the bare child name, while length > 1 appends
  an index with width-dependent zero padding.
- This makes machine parsing and comparing names difficult. The issue proposes
  bracketed names such as `object.member[0]`.

## Repository evidence

### SimObjectVector object names

`src/python/m5/params/base_params.py` contains the core special case:

- `len(self) == 1`: child parent/name is set to the vector field name unchanged.
- `len(self) > 1`: child names are generated as `name%0*d` with decimal width
  based on vector length.

This means a vector field can produce `cpu`, `cpu0`, `cpu1`, `cpu01`, etc.
depending on vector length.

### Text stats vector names

`src/base/stats/text.cc` has another length-1 special case in
`VectorPrint::operator()`.

Observed with existing `tests/gem5/stats/configs/pystat_vector_check.py`:

```text
# one-element vector
system.vector_stat                                 44                       (Count)

# two-element vector
system.vector_stat::0                              44                       (Count)
system.vector_stat::1                              55                       (Count)
```

Even when the one-element vector has a subname, text output still prints the
base stat name:

```text
system.vector_stat                                 44                       (Count)
```

The default vector separator is `::`, from `src/base/stats/info.cc`.

### SimObjectVector path output

Observed with existing
`tests/gem5/stats/configs/pystats_simobjectvector_check.py`:

```text
stat_testers0.placeholder                          11                       (Count)
stat_testers1.placeholder                          22                       # Index 2 desc. (Count)
stat_testers2.placeholder                          33                       (Count)
stat_testers3.index_4::0                           44                       # A SimStat Vector within a SimObject Vector. (Count)
```

The same run's `config.json` preserves the vector structure:

```text
"stat_testers": [
  ... "path": "stat_testers0" ...
  ... "path": "stat_testers1" ...
]
```

This suggests a migration tool is much safer if it can optionally consume
`config.json`, not just `stats.txt`.

### PyStats compatibility

Relevant files:

- `src/python/m5/stats/gem5stats.py`
- `src/python/m5/ext/pystats/group.py`
- `src/python/m5/ext/pystats/abstract_stat.py`
- `tests/pyunit/pystats/pyunit_pystats.py`

PyStats already represents SimObject vectors structurally with
`SimObjectVectorGroup`, while `AbstractStat._get_vector_item()` preserves old
attribute-style access such as `simstat.simobject_vector0`.

This is evidence that existing user-facing names and access patterns have
compatibility weight.

### Stats output options

Relevant files:

- `src/python/m5/main.py`
- `src/python/m5/stats/__init__.py`
- `src/python/m5/stats/gem5stats.py`
- `src/base/stats/text.cc`
- `src/base/stats/hdf5.cc`

gem5 supports `--stats-file`, with text as the default. HDF5 stores vector
metadata such as subnames. JSON/CSV visitors exist through PyStats, but their
behavior as drop-in migration inputs needs separate confirmation before relying
on them for #2744.

## Why not change default output first?

Default text output is a compatibility surface. A direct change would affect:

- downstream parsing scripts,
- reference stats comparisons,
- documentation and examples,
- tests that assert current names,
- user expectations around `cpu0`, `cpu01`, and `stat::subname`.

There are also real ambiguity cases:

- `system.cpu.foo` could be a single-element vector child or a normal child.
- `system.cpu0.foo` could be a vector element or a normal object whose name
  ends in digits.
- `system.cpu01.foo` could be a zero-padded vector element or a literal object
  name.
- `system.vector_stat` could be a scalar stat or a one-element vector stat.
- Rewriting `::` suffixes risks confusing stat-vector subnames with SimObject
  path components.

## Minimal PR plan

### PR 1: optional canonical mapping/report tool

Goal: report proposed canonical names without changing gem5 simulator output.

Likely files:

- `util/stats/name_canonicalizer.py`
- `util/stats-canonicalize.py`
- `tests/pyunit/stats/pyunit_stats_name_canonicalizer.py`
- `tests/pyunit/stats/fixtures/canonical_names/*.txt`
- `tests/pyunit/stats/fixtures/canonical_names/*.json`

Suggested CLI:

```text
util/stats-canonicalize.py \
  --input stats.txt \
  --output canonical-stats.txt \
  --mapping-output stats-name-map.json \
  [--config-json config.json] \
  [--allow-collisions]
```

Default behavior:

- Do not modify simulator output.
- Preserve comments, headers, footers, descriptions, and values where practical.
- Preserve `::` stat subname suffixes unless a specific stat-vector canonical
  rule is explicitly accepted by maintainers.
- Detect collisions and fail unless `--allow-collisions` is set.
- Mark ambiguous mappings as ambiguous instead of guessing.
- Be idempotent on already-canonical names.

Safe initial mapping rules:

- With `config.json`, canonicalize confirmed SimObjectVector path components:
  `stat_testers0.placeholder` -> `stat_testers[0].placeholder`.
- Preserve trailing stat subnames:
  `stat_testers3.index_4::0` -> `stat_testers[3].index_4::0`.
- For stats.txt-only input, do not infer that `foo0` is a vector element unless
  the rule is unambiguous and collision-free.

Unsafe by default:

- Inferring a length-1 SimObjectVector from `stats.txt` alone.
- Inferring that every trailing digit means a vector index.
- Rewriting `system.vector_stat` as `system.vector_stat[0]` without type
  metadata proving it is a one-element vector.

### PR 2: optional output mode only after maintainer buy-in

If maintainers like the sidecar mapping, a later PR could add an opt-in text
stats visitor parameter, for example:

```text
--stats-file=text://stats.txt?canonical_names=True
```

Likely files:

- `src/python/m5/stats/__init__.py`
- `src/base/stats/text.hh`
- `src/base/stats/text.cc`
- `src/python/pybind11/stats.cc`
- tests under `src/base/stats` and `tests/gem5/stats`

This should remain optional.

### PR 3: migration documentation

Likely files:

- `tests/gem5/stats/README.md`
- a docs page if maintainers prefer user docs over test docs

The docs should explain:

- current legacy naming,
- canonical naming goals,
- ambiguous cases,
- collision behavior,
- how to generate a mapping report,
- how to migrate downstream scripts.

## Test plan

Unit tests for the sidecar tool:

- SimObjectVector length 1 with `config.json`: reports ambiguity or maps only
  when metadata proves it.
- SimObjectVector length > 1: `cpu0`, `cpu1`, `cpu01` mapping.
- Names with existing digits: `l2cache0`, `vnet-0`, `bank01`.
- Names already containing brackets: idempotency.
- Names with `::` stat subnames: preserve suffixes.
- Text vector stat length 1 vs length 2.
- Collision detection: two old names mapping to one canonical name fails.
- Multiple stats dumps in one `stats.txt`.
- Comments/descriptions after values preserved.
- Ambiguous stats.txt-only input does not silently rewrite.

System-level smoke test, if needed later:

- Reuse `tests/gem5/stats/configs/pystats_simobjectvector_check.py`.
- Run gem5 to generate `stats.txt` and `config.json`.
- Run the sidecar tool on those outputs.
- Verify mapping report contains expected canonical names and no source-tree
  generated files.

Suggested commands:

```bash
python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit_stats_name_canonicalizer.py' -v
git diff --check
pre-commit run --files util/stats/name_canonicalizer.py util/stats-canonicalize.py tests/pyunit/stats/pyunit_stats_name_canonicalizer.py
./build/ALL/gem5.opt --outdir=/tmp/gem5-sov tests/gem5/stats/configs/pystats_simobjectvector_check.py
util/stats-canonicalize.py --input /tmp/gem5-sov/stats.txt --config-json /tmp/gem5-sov/config.json --mapping-output /tmp/gem5-sov/name-map.json
```

## Migration risks

- Default output changes would break existing parsing scripts.
- Reference stats files may need broad updates if default names change.
- Length-1 vectors are not recoverable from stats.txt alone.
- Existing object names can end in digits and collide with inferred vector
  names.
- Zero padding depends on vector length, so old names can change when a config
  crosses 10 elements.
- Some vector stat subnames are semantic strings, not numeric indices.
- HDF5/JSON/text outputs do not expose the same metadata in the same shape.

## Maintainer comment draft

```markdown
I would like to take a small first pass at this, if that sounds useful.

Given the compatibility risk, I would avoid changing default text stats output
initially. My proposed first PR would be an optional sidecar tool that reads an
existing `stats.txt` and emits a mapping report from legacy names to proposed
canonical names. If `config.json` is provided, it can safely identify
SimObjectVector path components such as `cpu0` -> `cpu[0]`; without metadata it
would report ambiguous cases instead of guessing.

I would keep `::` stat subname suffixes preserved in the first pass and add
collision detection so two old names cannot silently map to one canonical name.
The PR would be limited to the tool plus fixture-based Python tests. It would
not change simulator behavior or default stats output.

If that direction looks acceptable, a later PR could discuss an opt-in stats
visitor mode such as `text://stats.txt?canonical_names=True`, but I would not
start there.
```

## Current conclusion

For a first contribution, the safest useful work is a report-first optional
canonicalizer that proves the migration rules and ambiguity handling. A direct
default naming change should wait until maintainers agree on the canonical
scheme and migration path.
