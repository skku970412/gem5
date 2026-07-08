# gem5 issue #2744 comment

Issue: https://github.com/gem5/gem5/issues/2744

Comment posted: https://github.com/gem5/gem5/issues/2744#issuecomment-4900947219

## Comment

```markdown
I would like to take a small first pass at this, if that sounds useful.

Given the compatibility risk, I would avoid changing default text stats output initially. My proposed first PR would be an optional sidecar tool that reads an existing `stats.txt` and emits a mapping report from legacy names to proposed canonical names. If `config.json` is provided, it can safely identify SimObjectVector path components such as `cpu0` -> `cpu[0]`; without metadata it would report ambiguous cases instead of guessing.

I would keep `::` stat subname suffixes preserved in the first pass and add collision detection so two old names cannot silently map to one canonical name. The PR would be limited to the tool plus fixture-based Python tests. It would not change simulator behavior or default stats output.

If that direction looks acceptable, a later PR could discuss an opt-in stats visitor mode such as `text://stats.txt?canonical_names=True`, but I would not start there.
```

## Next action

Wait for maintainer direction before implementing #2744. The first implementation
should remain a sidecar report tool unless maintainers prefer a different path.
