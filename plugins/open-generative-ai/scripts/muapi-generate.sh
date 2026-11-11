#!/usr/bin/env bash
# Submit a MuAPI generation job, poll until it finishes, print the result JSON.
# Usage: muapi-generate.sh <endpoint> '<json body>' [--download DIR]
# Upload a local file:  muapi-generate.sh --upload <path>   (prints hosted URL)
# Requires MUAPI_API_KEY. Needs curl and jq.
set -euo pipefail
BASE="${MUAPI_BASE_URL:-https://api.muapi.ai}"
: "${MUAPI_API_KEY:?Set MUAPI_API_KEY (get one at https://muapi.ai)}"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }

if [[ "${1:-}" == "--upload" ]]; then
  [[ -f "${2:-}" ]] || { echo "usage: $0 --upload <file>" >&2; exit 2; }
  curl -fsS -X POST "$BASE/api/v1/upload_file" -H "x-api-key: $MUAPI_API_KEY" -F "file=@$2" \
    | jq -r '.url // .file_url // .data.url'
  exit 0
fi

endpoint="${1:?usage: $0 <endpoint> '<json body>' [--download DIR]}"
body="${2:?missing JSON body}"
download=""
[[ "${3:-}" == "--download" ]] && download="${4:?missing download dir}"
echo "$body" | jq -e . >/dev/null || { echo "body is not valid JSON" >&2; exit 2; }

submit=$(curl -fsS -X POST "$BASE/api/v1/$endpoint" \
  -H "Content-Type: application/json" -H "x-api-key: $MUAPI_API_KEY" -d "$body")
id=$(echo "$submit" | jq -r '.request_id // .id // empty')
if [[ -z "$id" ]]; then echo "$submit"; exit 0; fi
echo "submitted request_id=$id" >&2

timeout="${MUAPI_TIMEOUT_SECONDS:-1800}"
start=$(date +%s)
while :; do
  sleep 3
  res=$(curl -fsS "$BASE/api/v1/predictions/$id/result" -H "x-api-key: $MUAPI_API_KEY" || true)
  status=$(echo "${res:-{}}" | jq -r '.status // "" | ascii_downcase' 2>/dev/null || echo "")
  case "$status" in
    completed|succeeded|success) break ;;
    failed|error|cancelled|canceled) echo "$res" >&2; exit 1 ;;
  esac
  if (( $(date +%s) - start > timeout )); then echo "timed out; request_id=$id" >&2; exit 3; fi
done

echo "$res"
if [[ -n "$download" ]]; then
  mkdir -p "$download"
  echo "$res" | jq -r '(.outputs // [])[] , (.url // empty), (.output.url // empty)' | sort -u | while read -r u; do
    [[ "$u" == http* ]] || continue
    f="$download/$(basename "${u%%\?*}")"
    curl -fsSL "$u" -o "$f" && echo "saved $f" >&2
  done
fi
