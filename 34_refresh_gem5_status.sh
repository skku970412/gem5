#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM5_DIR="${ROOT_DIR}/gem5"
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
            --json number,state,isDraft,mergeable,mergeStateStatus,reviewDecision,baseRefName,headRefName,updatedAt,mergedAt,url,comments,reviews,labels \
            --jq '{number,state,isDraft,mergeable,mergeStateStatus,reviewDecision,baseRefName,headRefName,updatedAt,mergedAt,url,labels:[.labels[].name],commentCount:(.comments|length),reviewCount:(.reviews|length),lastCommentUrl:(.comments[-1].url // null),lastReviewState:(.reviews[-1].state // null)}'
    else
        api_get "pulls/${pr}" | jq '{
            error:._error,
            number,
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
            url:.html_url,
            labels:[.labels[]?.name],
            commentCount:.comments,
            reviewCommentCount:.review_comments
        }'
    fi
}

issue_summary() {
    local issue="$1"
    if [[ "${have_gh}" -eq 1 ]]; then
        gh issue view "${issue}" \
            --repo "${REPO}" \
            --json state,updatedAt,url,comments \
            --jq '{state,updatedAt,url,commentCount:(.comments|length),lastCommentUrl:(.comments[-1].url // null)}'
    else
        api_get "issues/${issue}" | jq '{
            error:._error,
            state,
            updatedAt:.updated_at,
            url:.html_url,
            commentCount:.comments
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

queued_jobs_for_branch() {
    local branch="$1"
    if [[ "${have_gh}" -eq 1 ]]; then
        local run_id
        run_id="$(
            gh run list \
                --repo "${REPO}" \
                --branch "${branch}" \
                --limit 1 \
                --json databaseId \
                --jq '.[0].databaseId // ""'
        )"
        if [[ -n "${run_id}" ]]; then
            echo "run_id=${run_id}"
            gh api "repos/${REPO}/actions/runs/${run_id}/jobs" \
                --jq '.jobs[] | select(.status != "completed") | {name,status,conclusion,labels,runner_name,started_at,html_url}'
        else
            echo "No ${branch} run found"
        fi
        return
    fi

    local run_id
    run_id="$(api_get "actions/runs?branch=${branch}&per_page=1" | jq -r '.workflow_runs[0].id // ""')"
    if [[ -z "${run_id}" ]]; then
        echo "No ${branch} run found"
        return
    fi

    echo "run_id=${run_id}"
    api_get "actions/runs/${run_id}/jobs" | jq \
        '.jobs[] | select(.status != "completed") | {name,status,conclusion,labels,runner_name,started_at,html_url}'
}

cd "${GEM5_DIR}" || exit 1

echo "== Timestamp =="
date -u '+%Y-%m-%d %H:%M:%S UTC'

echo
echo "== Local Branch =="
git status --short --branch

echo
if [[ "${have_gh}" -eq 1 ]]; then
    echo "== GitHub Access =="
    echo "Using gh"
else
    echo "== GitHub Access =="
    echo "gh not found; using unauthenticated public GitHub API fallback"
fi

echo
echo "== Open PR Summary =="
for pr in 3291 3292 3293 3241; do
    echo "-- PR #${pr} --"
    pr_summary "${pr}"
done

echo
echo "== Related Issue Summary =="
for issue in 1644 2744 3235; do
    echo "-- Issue #${issue} --"
    issue_summary "${issue}"
done

echo
echo "== PR Checks =="
for pr in 3291 3292 3293; do
    echo "-- PR #${pr} checks --"
    pr_checks "${pr}"
done

echo
echo "== Relevant Actions Runs =="
for branch in stats-txt-parser-pyunit fix-chi-protocol-case stats-name-canonicalizer; do
    echo "-- ${branch} --"
    branch_runs "${branch}"
done

echo
    echo "== #3291 Queued Job Details =="
queued_jobs_for_branch stats-txt-parser-pyunit

echo
echo "== Branch Drift =="
git fetch origin
for branch in stats-txt-parser-pyunit fix-chi-protocol-case stats-name-canonicalizer; do
    printf '%s ' "${branch}"
    git rev-list --left-right --count "origin/develop...${branch}"
done
printf 'parser->reset '
git rev-list --left-right --count stats-txt-parser-pyunit...stats-reset-validator
printf 'reset->docs '
git rev-list --left-right --count stats-reset-validator...stats-reset-validation-docs

echo
echo "== Current Waiting Snapshot =="
if [[ -f "${ROOT_DIR}/33_current_waiting_state.md" ]]; then
    sed -n '1,140p' "${ROOT_DIR}/33_current_waiting_state.md"
else
    echo "33_current_waiting_state.md not found"
fi

echo
echo "== Action Hints =="
cat <<'EOF'
- If #3291 has parser review comments: edit only tests/pyunit/stats files.
- If #3291 merges: rebase/open stats-reset-validator using 30_next_action_checklist.md.
- If #3292 gets review: keep the fix no-directory-rename unless maintainers ask otherwise.
- If #3292 CI runs and fails: inspect the job log before changing the branch.
- If #3293 gets maintainer direction: keep default stats output unchanged.
- If #3241 asks for help: contribute focused tests only; do not take over implementation.
- If nothing changed: do not post to GitHub; follow 35_maintainer_followup_policy.md.
EOF
