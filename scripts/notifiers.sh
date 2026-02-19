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
  bash scripts/notifiers.sh add <channel> <target> [account_id]
  bash scripts/notifiers.sh remove <index>
EOF
}

cmd="${1:-}"
case "$cmd" in
  list)
    ensure_config
    jq -r '.channels // [] | to_entries[] | "[\(.key)] channel=\(.value.channel // "<missing>") target=\(.value.target // "<missing>") account_id=\(.value.account_id // "")"' "$CONFIG_PATH"
    ;;

  add)
    ensure_config
    channel="${2:-}"
    target="${3:-}"
    account_id="${4:-}"
    [[ -n "$channel" ]] || { echo "Channel is required" >&2; exit 1; }
    [[ -n "$target" ]] || { echo "Target is required" >&2; exit 1; }

    if [[ -n "$account_id" ]]; then
      jq --arg channel "$channel" --arg target "$target" --arg account "$account_id" \
        '.channels += [{"channel":$channel,"target":$target,"account_id":$account}]' \
        "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    else
      jq --arg channel "$channel" --arg target "$target" \
        '.channels += [{"channel":$channel,"target":$target}]' \
        "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    fi

    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    echo "Added channel route: channel=$channel target=$target"
    ;;

  remove)
    ensure_config
    idx="${2:-}"
    [[ "$idx" =~ ^[0-9]+$ ]] || { echo "Index must be a non-negative integer" >&2; exit 1; }
    count="$(jq -r '(.channels // []) | length' "$CONFIG_PATH")"
    (( idx < count )) || { echo "Index out of range. Current channel count: $count" >&2; exit 1; }
    jq --argjson i "$idx" '.channels |= (to_entries | map(select(.key != $i)) | map(.value))' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    echo "Removed channel index $idx"
    ;;

  *)
    usage
    exit 1
    ;;
esac
