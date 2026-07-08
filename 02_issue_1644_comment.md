Hi, could I take a first pass at this?

I would keep the scope small and split it into reviewable pieces:

1. Add a small `stats.txt` parser for tests that can handle multiple dumps in one file, with fixture-based unit tests.
2. Add a reset validation test that generates the before/reset/after dumps inside the same test invocation, so it does not depend on fixed reference stats files or test runner ordering.
3. Add short documentation for extending the reset validator, including how to treat lifetime/constant stats and zero-valued stats that may be omitted from `stats.txt`.

For the first reset validator, I would start with a minimal deterministic workload/config and compare only a narrow set of resettable stats. I would explicitly allowlist lifetime or constant values such as `simFreq`/`finalTick`-style stats rather than trying to compare every stat in the first PR.

If that direction sounds reasonable, I can start with the parser utility PR first.
