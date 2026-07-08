#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./43_apply_github_pr_updates.sh [--dry-run]
  ./43_apply_github_pr_updates.sh --apply [--post-comments] [--only 3291|3292|all]

Updates currently stale gem5 PR metadata:
  - #3291 body from 03_pr1_body.md
  - #3292 title and body from 13_chi_macos_case_pr_body.md

By default this is a dry run. Use --apply to call the GitHub API.
Set GITHUB_TOKEN or GH_TOKEN before --apply.

Comments are not posted unless --post-comments is also passed.
EOF
}

mode="dry-run"
post_comments=0
only="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            mode="dry-run"
            ;;
        --apply)
            mode="apply"
            ;;
        --post-comments)
            post_comments=1
            ;;
        --only)
            if [[ $# -lt 2 ]]; then
                echo "--only requires 3291, 3292, or all" >&2
                exit 2
            fi
            only="$2"
            case "$only" in
                3291|3292|all)
                    ;;
                *)
                    echo "--only requires 3291, 3292, or all" >&2
                    exit 2
                    ;;
            esac
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_api="https://api.github.com/repos/gem5/gem5"
token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

pr3291_body="$script_dir/03_pr1_body.md"
pr3292_body="$script_dir/13_chi_macos_case_pr_body.md"

for path in "$pr3291_body" "$pr3292_body"; do
    if [[ ! -f "$path" ]]; then
        echo "missing required file: $path" >&2
        exit 1
    fi
done

if [[ "$mode" == "apply" && -z "$token" ]]; then
    echo "GITHUB_TOKEN or GH_TOKEN is required for --apply" >&2
    exit 1
fi

json_payload_file() {
    local output="$1"
    local title="$2"
    local body_file="$3"

    python3 - "$title" "$body_file" > "$output" <<'PY'
import json
from pathlib import Path
import sys

title = sys.argv[1]
body = Path(sys.argv[2]).read_text(encoding="utf-8")
payload = {"body": body}
if title != "-":
    payload["title"] = title
print(json.dumps(payload))
PY
}

json_comment_file() {
    local output="$1"
    local body_file="$tmp_dir/$(basename "$output" .json).md"

    cat > "$body_file"
    python3 - "$output" "$body_file" <<'PY'
import json
from pathlib import Path
import sys

body = Path(sys.argv[2]).read_text(encoding="utf-8")
with open(sys.argv[1], "w", encoding="utf-8") as payload:
    payload.write(json.dumps({"body": body}))
PY
}

api_call() {
    local method="$1"
    local url="$2"
    local payload="$3"

    if [[ "$mode" == "dry-run" ]]; then
        echo "DRY-RUN $method $url"
        echo "  payload: $payload"
        return
    fi

    curl -fsS \
        -X "$method" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        --data @"$payload" \
        "$url" >/dev/null
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Mode: $mode"
echo "Repository: gem5/gem5"

payload_3291="$tmp_dir/pr3291.json"
if [[ "$only" == "3291" || "$only" == "all" ]]; then
    json_payload_file "$payload_3291" "-" "$pr3291_body"
    api_call PATCH "$repo_api/pulls/3291" "$payload_3291"
fi

payload_3292="$tmp_dir/pr3292.json"
if [[ "$only" == "3292" || "$only" == "all" ]]; then
    json_payload_file \
        "$payload_3292" \
        "mem-ruby: avoid CHI generated include case mismatch" \
        "$pr3292_body"
    api_call PATCH "$repo_api/pulls/3292" "$payload_3292"
fi

if [[ "$post_comments" -eq 1 ]]; then
    if [[ "$only" == "3291" || "$only" == "all" ]]; then
        comment_3291="$tmp_dir/comment_3291.json"
        json_comment_file "$comment_3291" <<'EOF'
Thanks for the review comments. I pushed `6e24b3b44a` addressing them:

- integer-looking stat values now parse as `int`, preserving large gem5 counters/ticks beyond float's exact 53-bit range;
- decimal, scientific notation, `nan`, and `inf` values still parse as `float`;
- the edge-value fixture now covers `18446744073709551615`;
- the copyright holder in the new parser/test Python files is updated to `Sungkyunkwan University`.

Local checks:
- `python3 -m unittest discover -s tests/pyunit/stats -p 'pyunit*.py' -v`
- `pre-commit run --files tests/pyunit/stats/stats_txt.py tests/pyunit/stats/pyunit_stats_txt.py tests/pyunit/stats/fixtures/edge_values.txt`
- `git diff --check origin/develop...HEAD`
- `git diff --check`
- `./build/NULL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats`

I also attempted a default `ALL` build, but this local container has an inconsistent protobuf installation: `pkg-config` reports protobuf 3.12.4 while `protoc` and headers are 25.3, and `scons build/ALL/gem5.opt -j4` failed at link with protobuf/absl undefined references. The parser change is test-local and does not touch protobuf or simulator build behavior.
EOF
        api_call POST "$repo_api/issues/3291/comments" "$comment_3291"
    fi

    if [[ "$only" == "3292" || "$only" == "all" ]]; then
        comment_3292="$tmp_dir/comment_3292.json"
        json_comment_file "$comment_3292" <<'EOF'
Thanks for the feedback. I agree the directory rename has a higher downstream cost than the CI issue justifies, so I force-pushed a smaller version that keeps `src/mem/ruby/protocol/chi` unchanged.

The new version only avoids spelling SLICC-generated CHI headers through a source-tree path whose case can differ on macOS. It uses generated-header basename includes from CHI-specific sources and adds the generated CHI protocol directory to the local build include path.

Local checks:
- `git diff --check origin/develop...HEAD`
- `pre-commit run --files $(git diff --name-only origin/develop...HEAD)`
- `scons build/ALL/python/_m5/param_CHIGenericController.o -j4`
- `scons build/ALL/mem/ruby/protocol/chi/generic/CHIGenericController.o build/ALL/mem/ruby/protocol/chi/generic/CBusy.o build/ALL/python/_m5/param_CHIGenericController.o -j4`

If this still feels too invasive relative to the CI-only failure, I am fine closing it and keeping #3291 scoped to parser work.
EOF
        api_call POST "$repo_api/issues/3292/comments" "$comment_3292"
    fi
else
    echo "Comments: skipped; pass --post-comments with --apply to post them."
fi

echo "Done."
