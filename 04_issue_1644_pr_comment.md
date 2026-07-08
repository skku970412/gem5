I opened #3291 as a small first step toward this issue.

That PR only adds a test-local parser for multi-dump `stats.txt` files with pyunit fixtures. It does not change simulator behavior or the stats output format.

If that direction looks acceptable, the follow-up would be a reset validation test that generates before/reset/after dumps in the same gem5 invocation and compares a narrow set of resettable stats, with documented exclusions for lifetime/constant stats such as `simFreq`/`finalTick`-style values.
