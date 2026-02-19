#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.json"
EXAMPLE_PATH="${ROOT_DIR}/config.example.json"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v openclaw >/dev/null || { echo "openclaw CLI is required" >&2; exit 1; }

[[ -f "$CONFIG_PATH" ]] || cp "$EXAMPLE_PATH" "$CONFIG_PATH"

echo "== x-user-watch doctor =="

handles_count="$(jq -r '(.handles // []) | length' "$CONFIG_PATH")"
channels_count="$(jq -r '(.channels // []) | length' "$CONFIG_PATH")"

echo "handles:  $handles_count"
echo "channels: $channels_count"

if [[ "$handles_count" -le 0 ]]; then
  echo "[FAIL] no handles configured"
else
  echo "[ OK ] handles configured"
fi

if [[ "$channels_count" -le 0 ]]; then
  echo "[FAIL] no channels configured"
else
  echo "[ OK ] channels configured"
fi

rss_bases_json="$(jq -c 'if (.rss_bases // null) != null then .rss_bases else [(.rss_base // "https://nitter.net")] end' "$CONFIG_PATH")"

echo "\n-- feed source checks --"
while IFS= read -r base; do
  [[ -n "$base" ]] || continue
  first_handle="$(jq -r '.handles[0] // "elonmusk"' "$CONFIG_PATH")"
  url="${base%/}/${first_handle}/rss"
  : >/tmp/x-user-watch-doctor.tmp
  code="$(curl -sS -o /tmp/x-user-watch-doctor.tmp -w '%{http_code}' "$url" || true)"
  size="$(wc -c </tmp/x-user-watch-doctor.tmp 2>/dev/null || echo 0)"
  if grep -qiE '<rss|<feed' /tmp/x-user-watch-doctor.tmp 2>/dev/null; then
    echo "[ OK ] $base (http=$code, bytes=$size, rss=yes)"
  else
    echo "[WARN] $base (http=$code, bytes=$size, rss=no)"
  fi
done < <(jq -r '.[]' <<<"$rss_bases_json")

echo "\n-- notifier dry run --"
if /root/.openclaw/workspace/x-user-watch/scripts/notify.sh "x-user-watch doctor" "delivery check" "https://example.com"; then
  echo "[ OK ] notify.sh executed"
else
  echo "[FAIL] notify.sh failed"
fi
