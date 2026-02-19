#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.json"
EXAMPLE_PATH="${ROOT_DIR}/config.example.json"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

ensure_config() {
  if [[ ! -f "$CONFIG_PATH" ]]; then
    cp "$EXAMPLE_PATH" "$CONFIG_PATH"
    echo "Created config.json from config.example.json"
  fi
}

usage() {
  cat <<EOF
Usage:
  bash scripts/notifiers.sh list
  bash scripts/notifiers.sh remove <index>
EOF
}

cmd="${1:-}"
case "$cmd" in
  list)
    ensure_config
    jq -r '.notifiers // [] | to_entries[] | "[\(.key)] \(.value.type // "<missing-type>")"' "$CONFIG_PATH"
    ;;

  remove)
    ensure_config
    idx="${2:-}"
    [[ "$idx" =~ ^[0-9]+$ ]] || { echo "Index must be a non-negative integer" >&2; exit 1; }
    count="$(jq -r '(.notifiers // []) | length' "$CONFIG_PATH")"
    (( idx < count )) || { echo "Index out of range. Current notifier count: $count" >&2; exit 1; }
    jq --argjson i "$idx" '.notifiers |= (to_entries | map(select(.key != $i)) | map(.value))' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    echo "Removed notifier index $idx"
    ;;

  *)
    usage
    exit 1
    ;;
esac
