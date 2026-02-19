#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.json"

if [[ ! -f "$CONFIG_PATH" ]]; then
  cp "${ROOT_DIR}/config.example.json" "$CONFIG_PATH"
  echo "Created config.json from config.example.json"
fi

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v openclaw >/dev/null || { echo "openclaw CLI is required" >&2; exit 1; }

TITLE="${1:-New post}"
BODY="${2:-}"
URL="${3:-}"
MESSAGE="$TITLE\n$BODY\n$URL"

COUNT="$(jq -r '(.channels // []) | length' "$CONFIG_PATH")"
[[ "$COUNT" -gt 0 ]] || {
  echo "channels is missing or empty in config.json" >&2
  exit 1
}

send_one() {
  local idx="$1"
  local channel target account_id
  channel="$(jq -r ".channels[$idx].channel // \"\"" "$CONFIG_PATH")"
  target="$(jq -r ".channels[$idx].target // \"\"" "$CONFIG_PATH")"
  account_id="$(jq -r ".channels[$idx].account_id // \"\"" "$CONFIG_PATH")"

  [[ -n "$channel" ]] || { echo "channels[$idx].channel is missing" >&2; return 1; }
  [[ -n "$target" ]] || { echo "channels[$idx].target is missing" >&2; return 1; }

  if [[ -n "$account_id" ]]; then
    openclaw message send --channel "$channel" --account "$account_id" --target "$target" --message "$MESSAGE" >/dev/null
  else
    openclaw message send --channel "$channel" --target "$target" --message "$MESSAGE" >/dev/null
  fi
}

failed=0
for ((i=0; i<COUNT; i++)); do
  if ! send_one "$i"; then
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
