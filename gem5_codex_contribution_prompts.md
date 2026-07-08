# gem5 Contribution Codex Prompt Set

아래는 **gem5 기여용 Codex 프롬프트 세트**입니다. 그대로 복붙해서 세션별로 돌리면 됩니다. 방향은 이전 플랜 그대로 **stats reliability / reset validation / machine-readable stats / live stats review**입니다.

gem5는 첫 기여자에게 open issue를 확인하고, 맡아도 되는지 댓글로 묻는 흐름을 권장합니다. 또한 `develop` 브랜치 위에서 작업하고, PR은 작고 focused하게 유지하라고 안내합니다. 테스트 문서도 CPP unit test, Python unit test, system-level quick test 실행을 명시합니다. 이 원칙을 프롬프트에 강하게 박아두는 게 중요합니다. ([gem5][1])

추가 운영 원칙:

- 구현에서 끝내지 말고 GitHub PR 생성, PR 본문 작성, CI 확인, 리뷰 대응까지 포함한다.
- CI나 테스트가 실패하면 먼저 실패 로그를 확인하고, 내 변경 때문인지 기존/무관한 문제인지 구분한다.
- 내 변경으로 깨진 부분은 같은 브랜치에서 최소 수정하고 다시 검증한다.
- 무관한 실패는 원 PR에 섞지 말고, 필요하면 별도 작은 PR로 고친다.
- 유지보수자 피드백이 오면 범위를 넓히기보다 요청된 부분만 고치고 검증 결과를 댓글/PR 본문에 갱신한다.
- 스택 PR은 선행 PR이 merge된 뒤 rebase해서 diff가 한 logical change만 남는지 확인한 후 연다.

---

## 0. 모든 Codex 세션에 붙일 공통 프롬프트

모든 작업 프롬프트 맨 위에 이걸 붙이세요.

```text
You are working in the upstream gem5 repository:
https://github.com/gem5/gem5

Hard constraints:
- Work on top of the `develop` branch.
- Do not make broad unrelated changes.
- Do not reformat files unrelated to this task.
- Do not invent gem5 APIs. Inspect the repository first.
- Keep the PR small and focused: one logical change only.
- Prefer tests/utilities/docs before simulator-behavior changes.
- Preserve backwards compatibility unless the task explicitly requires otherwise.
- Follow local style, naming, import order, and existing test conventions.
- For Python, follow PEP 8 and existing gem5 style.
- Avoid generated-looking code, over-engineering, and giant abstractions.
- Every change must have a verification section.
- If a command cannot be run locally, explicitly say why and provide the exact command that should be run by a human.
- Opening the GitHub PR, monitoring CI, responding to review, and fixing failing parts are in scope unless the task explicitly says design-only or no edits.
- If CI fails, inspect logs, classify the failure as in-scope or unrelated, fix in-scope failures, and document unrelated failures with evidence.
- Keep unrelated fixes out of the PR; open a separate focused PR only when needed.

Before editing:
1. Inspect relevant directories and existing conventions.
2. Print a short implementation plan with exact files you intend to touch.
3. Wait for no approval; proceed with the smallest safe implementation.
4. After implementation, run the most targeted tests first.
5. Then run broader validation if feasible.

Output format:
- Summary
- Files changed
- Design rationale
- Verification commands run
- Verification results
- Risks / open questions
- Suggested PR title and PR description
```

---

## 1. Repo Scout: gem5 stats/testing 구조 조사

이건 제일 먼저 돌리세요. 구현시키지 말고 **조사 보고서만** 뽑게 합니다.

```text
[COMMON PROMPT ABOVE]

Task: Repo Scout for gem5 stats reset validation.

Context:
I want to contribute to gem5 issue #1644: "Add tests to ensure that stats reset when m5.stats.reset() is called." The issue says gem5 lacks tests validating reset behavior; inconsistent stats reset behavior can confuse simulation-result interpretation. It suggests a before/reset/after stats dump approach, while noting that fixed reference stats files are hard because test runner ordering is not guaranteed.

Your job:
Do not edit files. Inspect the repository and produce a technical plan.

Investigate:
1. Where gem5 Python unit tests live.
2. Where gem5 system-level tests live.
3. How tests invoke gem5 and inspect outputs.
4. Existing stats-related tests, if any.
5. Existing parser/util/helper patterns under tests/gem5, ext/testlib, util, or src.
6. How stats.txt dumps are delimited.
7. How m5.stats.dump() and m5.stats.reset() are used in Python configs/tests.
8. Which ISA/config would be the smallest reliable target for a reset test.
9. Whether a pure parser utility should live under tests/gem5/pyunit, tests/gem5/stats, util, or another existing location.

Required output:
- Proposed PR stack:
  PR 1: parser utility
  PR 2: reset validator
  PR 3: docs
- For each PR, list exact candidate files to add/modify.
- List existing tests to imitate.
- List commands to build and run the minimum relevant test set.
- List risks and how to avoid them.
- Do not write code.
```

---

## 2. 이슈 #1644에 남길 댓글 작성 프롬프트

gem5 공식 가이드는 첫 기여자가 이슈에 댓글로 맡아도 되는지 묻는 걸 권장합니다. 이 프롬프트는 그 댓글을 깔끔하게 만들게 합니다. ([gem5][1])

```text
[COMMON PROMPT ABOVE]

Task: Draft a GitHub issue comment for gem5 issue #1644.

Context:
Issue #1644 asks for tests to validate that stats reset when m5.stats.reset() is called. The issue explains that there is currently no such validation, that inconsistent reset behavior can mislead gem5 users, and that fixed reference stats files may be hard because test runner order is not guaranteed.

Goal:
Write a concise, maintainer-friendly comment asking whether I can take a first pass.

Tone:
- Respectful
- Specific
- Small-scope
- Non-invasive
- Shows that I read the issue carefully
- No hype
- No mention of AI/Codex

The comment should propose:
1. First PR: a small stats.txt parser for multi-dump files with fixtures/tests.
2. Second PR: a reset validation test that generates before/after stats in the same test invocation.
3. Third PR: docs explaining reset validation and excluded lifetime/constant stats.
4. Avoid fixed reference stats files.
5. Start with a minimal workload/config.
6. Use an allowlist for lifetime/constant stats such as simFreq/finalTick-like values.

Output only the final GitHub comment in Markdown.
```

---

## 3. PR 1 구현: stats.txt multi-dump parser

#1644 본문은 "dump stats -> reset -> run one tick -> dump again" 식의 비교를 제안합니다. 그래서 첫 PR은 reset validator의 기반이 되는 parser가 좋습니다. ([GitHub][2])

```text
[COMMON PROMPT ABOVE]

Task: Implement PR 1 for gem5 issue #1644: a small stats.txt parser utility for tests.

Goal:
Add a minimal, well-tested Python utility that can parse gem5 stats.txt files containing one or more statistics dumps. This is a non-invasive building block for a follow-up m5.stats.reset() validation test.

Hard scope limits:
- Do not change gem5 simulator behavior.
- Do not change stats output format.
- Do not add a large framework.
- Do not canonicalize stat names in this PR.
- Do not modify unrelated tests.
- Do not rely on external packages unless already used by gem5 tests.

Implementation requirements:
1. Inspect existing tests/gem5 and tests/gem5/pyunit conventions first.
2. Place the utility in the most appropriate existing test/util location.
3. Parse multiple stats dump sections from a single stats.txt file.
4. Preserve stat names exactly as printed.
5. Preserve substat names containing :: exactly.
6. Accept integer, float, scientific notation, nan/inf if existing parser style permits.
7. Ignore comment/header/footer lines safely.
8. Return an ordered structure so tests can compare dump order.
9. Provide clear errors for malformed input only when necessary.
10. Include fixture-based unit tests.

Test cases required:
- single dump with scalar stats
- multiple dumps in one file
- stats with :: subnames
- stats with zero values
- stats with scientific notation
- stats with comments/descriptions after the value
- empty or no-stat dump behavior
- malformed line behavior, if applicable

Verification:
Run the narrowest relevant Python tests first.
Then run pre-commit or formatting checks if available.
If feasible, run:
- git diff --check
- pre-commit run --files <changed files>
- ./build/ALL/gem5.opt tests/run_pyunit.py
If build/ALL/gem5.opt is missing, report the exact build command:
- scons build/ALL/gem5.opt -j$(nproc)

Final output:
- Summary
- Exact files changed
- Parser API
- Test coverage table
- Commands run and results
- Remaining risks
- Suggested PR title
- Suggested PR description
```

---

## 4. PR 1 검증 전용: parser를 공격적으로 깨뜨리는 세션

구현 세션과 별도로 **버그 헌터 세션**을 돌리세요.

```text
[COMMON PROMPT ABOVE]

Task: Adversarial review of the stats.txt parser PR.

You are not the implementer. Act as a strict reviewer trying to break the parser.

Do not add features unless required to fix correctness. First inspect the diff.

Review goals:
1. Find parsing assumptions that do not match gem5 stats.txt reality.
2. Find cases where comments/descriptions are parsed as values.
3. Find cases where multi-dump boundaries are wrong.
4. Find cases where stat names containing ::, dots, digits, underscores, brackets, or hyphens break.
5. Find float parsing bugs: scientific notation, nan, inf, negative values.
6. Find duplicate stat-name behavior within one dump.
7. Find behavior when a stat appears in dump 1 but not dump 2.
8. Find behavior when a dump has no stats.
9. Ensure no unrelated files were reformatted.
10. Ensure API is minimal and easy to use by future reset tests.

Required actions:
- Add missing tests for any real bug or edge case.
- If a design decision is ambiguous, document it in code comments or test names.
- Keep changes minimal.
- Do not over-engineer.

Verification commands:
- Run parser unit tests.
- Run git diff --check.
- Run pre-commit on changed files if available.
- Report any command not run.

Final output:
- Bugs found
- Fixes made
- New tests added
- Commands run
- Reviewer verdict: BLOCK / APPROVE WITH NITS / APPROVE
```

---

## 5. PR 2 구현: `m5.stats.reset()` validator

#1644의 핵심입니다. 고정 reference stats 파일에 의존하지 않고, 같은 테스트 실행 안에서 before/after를 생성하게 강하게 지시하세요. 이슈 본문도 runner 순서 때문에 reference stats 생성이 어렵다고 적고 있습니다. ([GitHub][2])

```text
[COMMON PROMPT ABOVE]

Task: Implement PR 2 for gem5 issue #1644: m5.stats.reset() validation test.

Context:
Issue #1644 says gem5 lacks tests to validate that stats reset when m5.stats.reset() is called. It suggests:
- run a configuration for some ticks
- dump stats
- reset stats
- run briefly
- dump stats again
Then compare the two dumps. Stats that remain the same or increase may not be resetting correctly, except for lifetime/constant stats such as finalTick or simFreq.

Critical design requirement:
Do NOT rely on fixed reference stats files generated by a separate test. The issue notes that test runner order is not guaranteed. Generate before/after stats in the same test invocation.

Scope:
- Build on the parser utility from PR 1 if available.
- Keep the first reset validator minimal.
- Prefer a small existing SE-mode workload/config if possible.
- Avoid simulator behavior changes unless absolutely necessary.
- Avoid broad architecture coverage in the first PR.

Implementation requirements:
1. Inspect existing m5.stats.dump() and m5.stats.reset() usage.
2. Create or reuse a tiny config/workload that:
   - runs briefly,
   - dumps stats,
   - calls m5.stats.reset(),
   - runs briefly again,
   - dumps stats again.
3. Parse the resulting stats.txt with the parser.
4. Compare selected resettable stats, not every stat initially.
5. Add a documented allowlist for lifetime/constant/non-reset stats.
6. If a stat is absent after reset, treat absence as zero only if that matches gem5 stats behavior and is documented in the test.
7. Use tolerance for floating-point comparisons.
8. Produce a readable failure message listing:
   - stat name
   - before value
   - after value
   - reason it failed
9. Keep runtime low enough for quick or targeted tests if possible.
10. Document why fixed reference stats are avoided.

Suggested initial stats to investigate, not blindly assume:
- simInsts
- simOps
- simTicks or similar
- selected CPU stats from the chosen config
- explicitly exclude simFreq/finalTick/host-runtime-like constants where appropriate

Validation strategy:
- First run only the new test.
- Then run relevant Python unit tests.
- Then run relevant system-level test UID if this becomes a system-level test.
- If feasible, run quick tests or the minimum supported suite.

Verification commands to attempt:
- git diff --check
- pre-commit run --files <changed files>
- scons build/ALL/gem5.opt -j$(nproc)
- ./build/ALL/gem5.opt tests/run_pyunit.py
- cd tests && ./main.py list -q --suites | grep -i stats
- cd tests && ./main.py run --skip-build --uid <new-or-relevant-suite-uid>

Final output:
- Summary
- Exact files changed
- Why the test is robust
- Which stats are checked
- Which stats are allowlisted and why
- How before/after dumps are generated
- Commands run and results
- Risks / follow-up work
- Suggested PR title
- Suggested PR description
```

---

## 6. PR 2 검증 전용: reset validator를 깨뜨리는 세션

이게 제일 중요합니다. reset test는 flake가 나면 바로 이미지가 나빠집니다.

```text
[COMMON PROMPT ABOVE]

Task: Adversarial review of the m5.stats.reset() validation PR.

You are a strict gem5 test reviewer. Your job is to find flakiness, false positives, false negatives, and bad assumptions.

Do not expand scope. Fix only correctness, robustness, and test reliability issues.

Audit checklist:
1. Does the test depend on test execution order? It must not.
2. Does it depend on fixed reference stats generated elsewhere? It must not.
3. Does it compare stats that are expected to be lifetime/constant values?
4. Is every allowlisted stat documented with a reason?
5. Does the test pass if a stat disappears after reset because zero-valued stats are omitted?
6. Does the test fail with a clear message when a resettable stat remains nonzero?
7. Are float comparisons tolerant where needed?
8. Are absent stats handled intentionally, not accidentally?
9. Is the workload deterministic enough?
10. Is runtime acceptable for the selected test category?
11. Does the test require external downloads/resources unnecessarily?
12. Does it work from a clean tree?
13. Does it leave generated files in the source tree?
14. Does it break parallel test execution?
15. Does it use temp directories correctly?
16. Does it work with `--skip-build` if system-level?
17. Does it follow existing ext/testlib/tests/gem5 conventions?
18. Are failure messages actionable for maintainers?
19. Is the PR still one logical change?
20. Are there any hidden simulator behavior changes?

Required destructive checks:
- Intentionally modify the comparison threshold or fixture locally to ensure the test fails when it should, then revert.
- Run the new test at least twice to check for flakiness.
- Run git diff after tests to ensure no generated files remain.
- Run git diff --check.
- Run pre-commit on changed files.

If you find a problem:
- Add the smallest fix.
- Add a regression test if appropriate.
- Document the behavior if it is a gem5 stats convention.

Final output:
- Flakiness risks found
- False-positive/false-negative risks found
- Fixes made
- Commands run
- Evidence that test fails when intentionally broken
- Reviewer verdict: BLOCK / APPROVE WITH NITS / APPROVE
```

---

## 7. PR 3 문서: stats reset validation guide

문서 PR은 설득용으로도 좋습니다. "테스트만 추가한 사람"보다 "유지보수자가 이후 확장할 수 있게 문서화한 사람"으로 보입니다.

```text
[COMMON PROMPT ABOVE]

Task: Implement PR 3: documentation for gem5 stats reset validation.

Context:
We added or plan to add tests for issue #1644 validating m5.stats.reset() behavior. The docs should explain how the reset validation works and how future contributors can extend it.

Scope:
- Documentation only unless a tiny comment/link change is needed.
- Do not change simulator behavior.
- Do not duplicate large existing documentation.
- Link or refer to existing test files where appropriate.

Documentation should cover:
1. Why stats reset validation matters.
2. What m5.stats.reset() validation is intended to catch.
3. Why before/after dumps are generated in the same test invocation.
4. Why fixed reference stats files are avoided.
5. What kinds of stats are resettable.
6. What kinds of stats are lifetime/constant/non-reset and why they may be excluded.
7. How zero-valued stats may be omitted and how the test handles absence.
8. How to add more stats/configurations/workloads to the validator.
9. How to run the relevant tests locally.
10. How to interpret failure messages.

Verification:
- Check links and file paths.
- Run markdown/lint/pre-commit if configured.
- Run git diff --check.
- If docs mention commands, verify they match gem5 TESTING.md conventions.

Final output:
- Summary
- Files changed
- Commands verified
- Suggested PR title
- Suggested PR description
```

---

## 8. #2744 구현 전 조사: canonical vector stats 설계 보고서

#2744는 vector stat 이름이 길이 1일 때 special case가 있어 machine parsing이 어렵고, bracketed naming 같은 canonical scheme이 제안되어 있습니다. 동시에 user-facing change라 optional/migration이 고민이라고 되어 있으므로, 바로 기본 출력 변경은 위험합니다. ([GitHub][3])

```text
[COMMON PROMPT ABOVE]

Task: Design-only investigation for gem5 issue #2744: canonical names for vector stats.

Do not edit files.

Context:
Issue #2744 says vector stats names have special cases that make machine parsing difficult, especially length-1 SimObject vectors and numbering differences. The issue discusses canonical bracketed naming like object.member[0], object.member[1], but notes this is a big user-facing change and should ideally be optional/migration-friendly.

Goal:
Produce a backwards-compatible implementation plan.

Investigate:
1. Where vector stat names are generated.
2. Where SimObjectVector naming is implemented.
3. Where stats output names are assembled.
4. Existing JSON/text stats output paths.
5. Existing command-line/config options that affect stats output.
6. How tests currently assert stats names.
7. Backwards compatibility risks.
8. Whether a sidecar utility is safer than changing default output.
9. Whether optional canonical output can be added without breaking existing users.
10. Collision risks: two old names mapping to one canonical name.

Required recommendation:
Choose one of:
A. sidecar canonicalizer utility first,
B. optional stats output mode,
C. direct default naming change.

Given this is a first contribution, strongly prefer A unless repository evidence suggests otherwise.

Required output:
- Recommended approach
- Exact files likely involved
- Minimal PR plan
- Migration risks
- Test plan
- Maintainer comment draft
- Do not write code
```

---

## 9. #2744 PR: optional canonicalizer utility

이건 기본 output을 바꾸지 않는 "안전한 PoC"입니다.

```text
[COMMON PROMPT ABOVE]

Task: Implement a backwards-compatible prototype for gem5 issue #2744: optional stats name canonicalizer.

Context:
Issue #2744 discusses canonical names for vector stats. The problem is machine parsing difficulty caused by special cases in vector naming. The issue explicitly notes that changing default naming is a large user-facing change and should ideally be optional or migration-friendly.

Goal:
Add a sidecar utility that reads an existing stats.txt and emits a canonicalized version or mapping report, without changing gem5 simulator output.

Hard constraints:
- Do not change default gem5 stats output.
- Do not change SimObject naming behavior.
- Do not change simulator behavior.
- Do not silently canonicalize ambiguous names if it can cause collisions.
- Mark the tool experimental if appropriate.
- Keep the PR small.

Implementation requirements:
1. CLI with --input and --output.
2. Optional --mapping-output to emit old-name -> canonical-name mapping.
3. Preserve comments/header/footer where reasonable, or document if not.
4. Canonicalize only patterns that can be handled safely.
5. Detect collisions and fail with a clear error unless --allow-collisions is explicitly provided.
6. Unit tests with fixtures.
7. Include examples in docs or tool help.
8. Make it easy to use with stats reset/parser tooling later.

Test cases required:
- length-1 vector-like name
- multi-element vector-like names
- names with existing digits
- names with :: substat suffixes
- names that should remain unchanged
- collision detection
- idempotency: canonicalizing already canonical names should not corrupt them
- malformed/ambiguous names

Verification:
- Run unit tests for the utility.
- Run git diff --check.
- Run pre-commit on changed files.
- Do not run full system-level tests unless needed, but report why not.

Final output:
- Summary
- Files changed
- Backwards compatibility explanation
- Collision handling design
- Test coverage table
- Commands run
- Suggested PR title
- Suggested PR description
```

---

## 10. #2744 검증 전용: migration/collision reviewer

```text
[COMMON PROMPT ABOVE]

Task: Adversarial review of the optional stats canonicalizer PR for gem5 issue #2744.

You are a strict backwards-compatibility reviewer.

Review goals:
1. Ensure default gem5 stats output is unchanged.
2. Ensure the tool cannot silently produce misleading canonical names.
3. Ensure collisions are detected.
4. Ensure already-canonical names are handled safely.
5. Ensure names with :: substats are preserved correctly.
6. Ensure the tool does not pretend to solve cases it cannot safely infer.
7. Ensure docs/help clearly say this is optional/experimental if appropriate.
8. Ensure tests cover ambiguous cases.
9. Ensure no simulator behavior changes slipped in.
10. Ensure no unrelated formatting changes.

Required checks:
- Compare before/after git diff for simulator source files.
- Run unit tests.
- Run a sample stats fixture through the tool twice and verify idempotency.
- Create a collision fixture and verify it fails clearly.
- Run git diff --check.
- Run pre-commit on changed files.

Final output:
- Backwards-compatibility verdict
- Collision-safety verdict
- Bugs found/fixed
- Commands run
- Reviewer verdict: BLOCK / APPROVE WITH NITS / APPROVE
```

---

## 11. #3235 / #3241 리뷰 지원 프롬프트

#3235는 live power modeling을 위해 simulation 중 stat 값을 이름으로 조회하고 싶다는 이슈이고, #3241은 그 구현 PR로 열려 있습니다. 여기서는 남의 PR을 가로채지 말고 **테스트/리뷰 지원**으로 들어가야 합니다. ([GitHub][4])

```text
[COMMON PROMPT ABOVE]

Task: Review and test support for gem5 issue #3235 and PR #3241.

Do not take over the PR. Do not rewrite the contributor's work. Act as a helpful reviewer/test contributor.

Context:
Issue #3235 asks for reading gem5 stats during simulation for live power modeling. It needs lookup by stat name during the run, including simple stats and a single value from multi-value stats using name::subname. PR #3241 is already open for this work.

Goal:
Find small, useful test or review contributions that help #3241 without duplicating or hijacking it.

Steps:
1. Fetch PR #3241 locally if possible.
2. Inspect the changed files.
3. Identify the runtime stats lookup API.
4. Identify missing tests for:
   - scalar stat lookup
   - multi-value stat lookup using name::subname
   - missing stat name
   - missing subname
   - malformed lookup expression
   - lookup before/after stats reset if relevant
   - values needed by power modeling, if exposed
5. Check whether the change interacts with #1644 stats reset validation.
6. Propose minimal test additions as a comment or small PR only if maintainers prefer.

Do not:
- Push a competing implementation.
- Refactor unrelated stats infrastructure.
- Make broad API changes.
- Criticize harshly.

Required output:
- Local test results if PR branch can be fetched
- Suggested review comments
- Suggested additional tests
- Whether I should open a small follow-up PR or just comment
- Draft GitHub comment in Markdown
```

---

## 12. 최종 PR 전 "빡센 게이트" 프롬프트

각 PR 올리기 전에 이걸 마지막으로 돌리세요.

```text
[COMMON PROMPT ABOVE]

Task: Final pre-PR gate for this gem5 contribution.

You are a release-blocking reviewer. Be strict.

Goal:
Decide whether this branch is ready to open as a gem5 pull request.

Checklist:
1. Is this PR one logical change?
2. Are all touched files necessary?
3. Are there unrelated formatting changes?
4. Does the commit message follow gem5 expectations?
5. Does the PR target `develop`?
6. Does it reference the relevant GitHub issue?
7. Does it preserve backwards compatibility?
8. Are tests included for new behavior?
9. Are tests deterministic?
10. Do tests avoid external downloads unless existing infra requires them?
11. Are failure messages actionable?
12. Are docs updated if behavior or workflow changed?
13. Are generated files absent from git diff?
14. Does `git diff --check` pass?
15. Does pre-commit pass on changed files?
16. Do targeted tests pass?
17. If broader tests were not run, is the reason documented?
18. Is the PR description honest about limitations?
19. Are there any TODOs/FIXMEs that should not be in upstream?
20. Would a gem5 maintainer see this as small and reviewable?

Commands to run:
- git status --short
- git diff --stat upstream/develop...HEAD
- git diff --check upstream/develop...HEAD
- pre-commit run --files $(git diff --name-only upstream/develop...HEAD)
- targeted unit tests for changed code
- if applicable: scons build/ALL/gem5.opt -j$(nproc)
- if applicable: ./build/ALL/gem5.opt tests/run_pyunit.py
- if applicable: cd tests && ./main.py list -q --suites
- if applicable: cd tests && ./main.py run --skip-build --uid <relevant-suite-uid>

If any command fails:
- Diagnose root cause.
- Fix if in scope.
- Otherwise explain clearly and mark PR as not ready.

Final output:
- READY / NOT READY
- Blocking issues
- Non-blocking nits
- Commands run
- Exact results
- Suggested PR title
- Final PR description
```

---

## 13. PR description 생성 프롬프트

검증 끝나면 PR 본문은 이걸로 만들면 됩니다.

```text
[COMMON PROMPT ABOVE]

Task: Write a gem5 pull request description for the current branch.

Requirements:
- No hype.
- Clear, technical, maintainer-friendly.
- Reference the relevant issue.
- Explain why the change is small and safe.
- Explain testing clearly.
- Mention limitations and follow-up work.
- Do not mention Codex or AI.

Use this structure:

Title:
<component>: <short action>

Summary:
- ...

Motivation:
- ...

Implementation:
- ...

Testing:
- [ ] command/result
- [ ] command/result

Compatibility:
- ...

Follow-up:
- ...

Now inspect the current diff and write the final PR title and body.
```

---

## 14. OpenAI Codex for OSS 신청용 "증거 패키지" 생성 프롬프트

PR 몇 개 만든 뒤, 신청 전에 이걸 돌리세요.

```text
Task: Create an OSS contribution evidence package for an OpenAI Codex for OSS application.

Context:
I contributed to gem5, a computer-system architecture simulator. My work focuses on stats reliability, m5.stats.reset() validation, machine-readable stats parsing, and stats infrastructure testing.

Do not exaggerate my role.
Do not claim I am a core maintainer unless the repository clearly says so.
Do not claim PRs are merged unless they are actually merged.
Do not mention private or unverifiable claims.

Collect:
1. Links to issues I worked on.
2. Links to PRs I opened.
3. Whether each PR is merged/open/reviewed.
4. What technical problem each PR solves.
5. What maintainer burden it reduces.
6. What verification I ran.
7. What follow-up work I proposed.

Write:
1. A 150-word summary.
2. A 500-word application answer.
3. A bullet list of evidence links.
4. A "maintainer automation impact" section.
5. A "future use of Codex/API credits" section.

Tone:
- Precise
- Honest
- Maintainer-focused
- No hype
- No unsupported claims

Key message:
I am building and upstreaming maintenance infrastructure for gem5 statistics reliability: reproducible stats parsing, reset validation, and machine-readable stats workflows that help maintainers and researchers trust simulation results.
```

---

## 15. PR/CI 운영 루프: 올리고 깨진 부분 계속 고치기

열린 PR이 생긴 뒤에는 이걸 반복해서 돌리세요. 새 구현이 아니라
**현재 PR 상태 확인 -> 실패 분류 -> 필요한 최소 수정 -> 재검증** 세션입니다.

```text
[COMMON PROMPT ABOVE]

Task: Operate the current gem5 PR queue and fix failing parts.

Context:
I have one or more open gem5 PRs. Keep the work maintainer-friendly: small
PRs, scoped fixes, clear CI diagnosis, and no unrelated churn.

Goal:
Check current PR/review/CI state, decide what needs action, and fix only
in-scope failures. If nothing changed, update local notes but do not post noisy
GitHub comments.

Required steps:
1. Refresh PR state with gh before trusting local notes.
2. Check review comments and CI results for each open PR.
3. If a check failed, inspect the failing log before editing.
4. Classify each problem:
   - in-scope bug in this PR,
   - unrelated upstream/infrastructure failure,
   - workflow approval/runner availability issue,
   - maintainer-requested change.
5. Fix in-scope failures on the correct branch only.
6. Keep unrelated fixes out of the PR; use a separate focused PR only if needed.
7. Rerun the narrow targeted tests first, then formatting/pre-commit checks.
8. Push only after verification passes.
9. Update PR comments or PR body only when there is new useful information.
10. Update local status/evidence notes with exact commands and results.

Useful local commands if available:
- ./34_refresh_gem5_status.sh
- ./38_verify_gem5_stack.sh
- ./39_capture_gem5_status_snapshot.sh

Final output:
- Current PR state
- Failures found
- Classification for each failure
- Fixes made
- Commands run and results
- PRs pushed or comments posted
- Next action / wait condition
```

---

## 내가 추천하는 실행 순서

```text
1. Prompt 1: Repo Scout
2. Prompt 2: #1644 comment 작성
3. Prompt 3: PR 1 parser 구현
4. Prompt 4: parser adversarial review
5. Prompt 12: PR gate
6. Prompt 13: PR description
7. Prompt 5: PR 2 reset validator 구현
8. Prompt 6: reset validator adversarial review
9. Prompt 12: PR gate
10. Prompt 13: PR description
11. Prompt 7: docs PR
12. Prompt 8~10: #2744 optional canonicalizer
13. Prompt 11: #3235/#3241 리뷰 지원
14. Prompt 14: 신청용 evidence package
15. Prompt 15: 열린 PR/CI 상태를 반복 확인하고 깨진 부분만 계속 고치기
```

가장 중요한 건 **구현 Codex 세션과 검증 Codex 세션을 분리**하는 것입니다. 같은 세션이 자기가 만든 코드를 검증하면 허술해질 수 있으니, "strict reviewer / adversarial reviewer / release-blocking reviewer" 역할을 따로 돌리는 게 좋습니다.

[1]: https://www.gem5.org/contributing "gem5: A guide to contributing"
[2]: https://github.com/gem5/gem5/issues/1644 "Add tests to ensure that stats reset when m5.stats.reset() is called · Issue #1644 · gem5/gem5 · GitHub"
[3]: https://github.com/gem5/gem5/issues/2744 "Canonical names for vector stats · Issue #2744 · gem5/gem5 · GitHub"
[4]: https://github.com/gem5/gem5/issues/3235 "Reading gem5 stats during simulation, for live power modeling · Issue #3235 · gem5/gem5 · GitHub"
