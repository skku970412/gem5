#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM5_DIR="${ROOT_DIR}/gem5"
SNAPSHOT_DIR="${ROOT_DIR}/status_snapshots"
REPO="gem5/gem5"
API_ROOT="https://api.github.com/repos/${REPO}"

if [[ ! -d "${GEM5_DIR}/.git" ]]; then
    echo "gem5 checkout not found at ${GEM5_DIR}" >&2
    exit 1
fi

have_gh=0
if command -v gh >/dev/null 2>&1; then
    have_gh=1
fi

api_get() {
    local response
    if response="$(curl -fsSL -H 'Accept: application/vnd.github+json' "${API_ROOT}/$1" 2>/dev/null)"; then
        printf '%s\n' "${response}"
    else
        printf '{"_error":"GitHub API request failed or rate-limited","path":"%s"}\n' "$1"
    fi
}

pr_summary() {
    local pr="$1"
    if [[ "${have_gh}" -eq 1 ]]; then
        gh pr view "${pr}" \
            --repo "${REPO}" \
            --json number,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision,baseRefName,headRefName,updatedAt,mergedAt,url \
            --jq '{number,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision,baseRefName,headRefName,updatedAt,mergedAt,url}'
    else
        api_get "pulls/${pr}" | jq '{
            error:._error,
            number,
            title,
            state,
            isDraft:.draft,
            mergeable,
            mergeStateStatus:.mergeable_state,
            reviewDecision:null,
            baseRefName:.base.ref,
            headRefName:.head.ref,
            headSha:.head.sha,
            updatedAt:.updated_at,
            mergedAt:.merged_at,
            url:.html_url
        }'
    fi
}

pr_checks() {
    local pr="$1"
    if [[ "${have_gh}" -eq 1 ]]; then
        gh pr checks "${pr}" --repo "${REPO}" || true
        return
    fi

    local sha
    sha="$(api_get "pulls/${pr}" | jq -r '.head.sha // empty')"
    if [[ -z "${sha}" ]]; then
        echo "checks unavailable: GitHub API request failed or rate-limited"
        return
    fi
    echo "head_sha=${sha}"
    echo "statuses:"
    api_get "commits/${sha}/status" | jq -r \
        '.statuses[]? | "  \(.context): \(.state) - \(.description // "")"'
    echo "check-runs:"
    api_get "commits/${sha}/check-runs" | jq -r \
        '.check_runs[]? | "  \(.name): \(.status) / \(.conclusion // "")"'
}

branch_runs() {
    local branch="$1"
    if [[ "${have_gh}" -eq 1 ]]; then
        gh run list --repo "${REPO}" --branch "${branch}" --limit 5
    else
        api_get "actions/runs?branch=${branch}&per_page=5" | jq -r \
            '.workflow_runs[]? | "  \(.id) \(.name): \(.status) / \(.conclusion // "") @ \(.head_sha[0:10])"'
    fi
}

mkdir -p "${SNAPSHOT_DIR}"

timestamp="$(date -u '+%Y%m%d_%H%M%SZ')"
outfile="${SNAPSHOT_DIR}/gem5_status_${timestamp}.md"

{
    echo "# gem5 status snapshot"
    echo
    echo "Captured: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo
    if [[ "${have_gh}" -eq 1 ]]; then
        echo "GitHub access: gh"
    else
        echo "GitHub access: public API fallback"
    fi
    echo
    echo "## Local Branch"
    echo
    echo '```text'
    git -C "${GEM5_DIR}" status --short --branch
    echo '```'
    echo
    echo "## Pull Requests"
    echo
    for pr in 3291 3292 3293 3241; do
        echo "### PR #${pr}"
        echo
        echo '```json'
        pr_summary "${pr}"
        echo '```'
        echo
    done
    echo "## Checks"
    echo
    for pr in 3291 3292 3293 3241; do
        echo "### PR #${pr}"
        echo
        echo '```text'
        pr_checks "${pr}"
        echo '```'
        echo
    done
    echo "## Recent Actions Runs"
    echo
    for branch in stats-txt-parser-pyunit fix-chi-protocol-case stats-name-canonicalizer; do
        echo "### ${branch}"
        echo
        echo '```text'
        branch_runs "${branch}"
        echo '```'
        echo
    done
    echo "## Branch Drift"
    echo
    echo '```text'
    git -C "${GEM5_DIR}" fetch origin
    for branch in stats-txt-parser-pyunit fix-chi-protocol-case stats-name-canonicalizer; do
        printf '%s ' "${branch}"
        git -C "${GEM5_DIR}" rev-list --left-right --count "origin/develop...${branch}"
    done
    printf 'parser->reset '
    git -C "${GEM5_DIR}" rev-list --left-right --count stats-txt-parser-pyunit...stats-reset-validator
    printf 'reset->docs '
    git -C "${GEM5_DIR}" rev-list --left-right --count stats-reset-validator...stats-reset-validation-docs
    echo '```'
    echo
    echo "## Triage Notes"
    echo
    echo "- Fix in-scope failures on the same branch and rerun targeted checks."
    echo "- Keep unrelated failures out of the PR; use a separate focused branch when needed."
    echo "- Do not post a GitHub comment just because this snapshot was captured."
} > "${outfile}"

echo "${outfile}"
