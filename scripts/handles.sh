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

normalize_handle() {
  local h="$1"
  h="${h#@}"
  echo "$h"
}

usage() {
  cat <<EOF
Usage:
  bash scripts/handles.sh list
  bash scripts/handles.sh add <handle>
  bash scripts/handles.sh remove <handle>
EOF
}

cmd="${1:-}"
case "$cmd" in
  list)
    ensure_config
    jq -r '.handles[]' "$CONFIG_PATH"
    ;;

  add)
    ensure_config
    handle="$(normalize_handle "${2:-}")"
    [[ -n "$handle" ]] || { echo "Handle is required" >&2; exit 1; }
    jq --arg h "$handle" '.handles += [$h] | .handles |= map(select(length>0)) | .handles |= unique' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    echo "Added @$handle"
    ;;

  remove)
    ensure_config
    handle="$(normalize_handle "${2:-}")"
    [[ -n "$handle" ]] || { echo "Handle is required" >&2; exit 1; }
    jq --arg h "$handle" '.handles -= [$h]' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"
    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    echo "Removed @$handle"
    ;;

  *)
    usage
    exit 1
    ;;
esac
