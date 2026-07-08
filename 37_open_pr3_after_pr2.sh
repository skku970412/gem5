#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM5_DIR="${ROOT_DIR}/gem5"
EXPECTED_FILES=("tests/gem5/stats/README.md")

create_pr=0
if [[ "${1:-}" == "--create" ]]; then
    create_pr=1
elif [[ "${1:-}" != "" ]]; then
    echo "usage: $0 [--create]" >&2
    exit 2
fi

cd "${GEM5_DIR}"

git fetch origin

if ! git merge-base --is-ancestor stats-reset-validator origin/develop; then
    echo "stats-reset-validator is not in origin/develop yet. Leaving branches unchanged."
    exit 0
fi

echo "stats-reset-validator is in origin/develop. Preparing PR3 branch."

git switch stats-reset-validation-docs
git rebase origin/develop

mapfile -t changed_files < <(git diff --name-only origin/develop...HEAD)

if [[ "${#changed_files[@]}" -ne "${#EXPECTED_FILES[@]}" ]]; then
    echo "Unexpected PR3 diff file count:" >&2
    printf '  %s\n' "${changed_files[@]}" >&2
    exit 1
fi

for expected in "${EXPECTED_FILES[@]}"; do
    if [[ "${changed_files[0]}" != "${expected}" ]]; then
        echo "Expected PR3 file missing from diff: ${expected}" >&2
        printf 'Current diff files:\n' >&2
        printf '  %s\n' "${changed_files[@]}" >&2
        exit 1
    fi
done

git diff --check origin/develop...HEAD
pre-commit run --files "${EXPECTED_FILES[@]}"
(
    cd tests
    ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
)

git push --force-with-lease fork stats-reset-validation-docs

if [[ "${create_pr}" -eq 1 ]]; then
    gh pr create \
        --repo gem5/gem5 \
        --base develop \
        --head skku970412:stats-reset-validation-docs \
        --title "tests: document stats reset validation" \
        --body-file "${ROOT_DIR}/32_pr3_body_current.md"
else
    echo
    echo "Dry run complete. To create PR3, re-run:"
    echo "  $0 --create"
fi
