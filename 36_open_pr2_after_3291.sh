#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM5_DIR="${ROOT_DIR}/gem5"
EXPECTED_FILES=(
    "tests/gem5/stats/configs/stats_reset_check.py"
    "tests/gem5/stats/test_stats_reset.py"
)
GITHUB_API="https://api.github.com/repos/gem5/gem5/pulls/3291"

create_pr=0
if [[ "${1:-}" == "--create" ]]; then
    create_pr=1
elif [[ "${1:-}" != "" ]]; then
    echo "usage: $0 [--create]" >&2
    exit 2
fi

cd "${GEM5_DIR}"

git fetch origin

merged_at=""

if git merge-base --is-ancestor stats-txt-parser-pyunit origin/develop; then
    merged_at="stats-txt-parser-pyunit is present in origin/develop"
elif command -v gh >/dev/null 2>&1; then
    merged_at="$(
        gh pr view 3291 \
            --repo gem5/gem5 \
            --json mergedAt \
            --jq '.mergedAt // ""'
    )"
else
    auth_header=()
    if [[ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
        auth_header=(
            -H "Authorization: Bearer ${GITHUB_TOKEN:-${GH_TOKEN:-}}"
            -H "X-GitHub-Api-Version: 2022-11-28"
        )
    fi

    api_response="$(
        curl -fsS \
            -H "Accept: application/vnd.github+json" \
            "${auth_header[@]}" \
            "${GITHUB_API}" 2>/dev/null || true
    )"

    if [[ -n "${api_response}" ]]; then
        merged_at="$(
            python3 -c 'import json, sys; print((json.load(sys.stdin).get("merged_at") or ""))' \
                <<< "${api_response}"
        )"
    fi
fi

if [[ -z "${merged_at}" ]]; then
    echo "PR #3291 is not merged yet, or merge state could not be determined. Leaving branches unchanged."
    exit 0
fi

echo "PR #3291 merged at ${merged_at}. Preparing PR2 branch."

git switch stats-reset-validator
git rebase origin/develop

mapfile -t changed_files < <(git diff --name-only origin/develop...HEAD)

if [[ "${#changed_files[@]}" -ne "${#EXPECTED_FILES[@]}" ]]; then
    echo "Unexpected PR2 diff file count:" >&2
    printf '  %s\n' "${changed_files[@]}" >&2
    exit 1
fi

for expected in "${EXPECTED_FILES[@]}"; do
    found=0
    for changed in "${changed_files[@]}"; do
        if [[ "${changed}" == "${expected}" ]]; then
            found=1
            break
        fi
    done
    if [[ "${found}" -ne 1 ]]; then
        echo "Expected PR2 file missing from diff: ${expected}" >&2
        printf 'Current diff files:\n' >&2
        printf '  %s\n' "${changed_files[@]}" >&2
        exit 1
    fi
done

git diff --check origin/develop...HEAD
pre-commit run --files "${EXPECTED_FILES[@]}"
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
(
    cd tests
    ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
)

git push --force-with-lease fork stats-reset-validator

if [[ "${create_pr}" -eq 1 ]]; then
    gh pr create \
        --repo gem5/gem5 \
        --base develop \
        --head skku970412:stats-reset-validator \
        --title "tests: validate m5.stats.reset output" \
        --body-file "${ROOT_DIR}/31_pr2_body_current.md"
else
    echo
    echo "Dry run complete. To create PR2, re-run:"
    echo "  $0 --create"
fi
