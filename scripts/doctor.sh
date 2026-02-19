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

feed_sources_json="$(jq -c '
  if (.rss_templates // null) != null then .rss_templates
  elif (.rss_bases // null) != null then .rss_bases
  else [(.rss_base // "https://nitter.net")]
  end
' "$CONFIG_PATH")"

echo
 echo "-- feed source checks --"
while IFS= read -r src; do
  [[ -n "$src" ]] || continue
  first_handle="$(jq -r '.handles[0] // "elonmusk"' "$CONFIG_PATH")"
  if [[ "$src" == *"{handle}"* ]]; then
    url="${src//\{handle\}/$first_handle}"
  else
    url="${src%/}/${first_handle}/rss"
  fi

  : >/tmp/x-user-watch-doctor.tmp
  code="$(curl -sSL -o /tmp/x-user-watch-doctor.tmp -w '%{http_code}' "$url" || true)"
  size="$(wc -c </tmp/x-user-watch-doctor.tmp 2>/dev/null || echo 0)"
  if grep -qiE '<rss|<feed' /tmp/x-user-watch-doctor.tmp 2>/dev/null; then
    echo "[ OK ] $url (http=$code, bytes=$size, rss=yes)"
  else
    echo "[WARN] $url (http=$code, bytes=$size, rss=no)"
  fi
done < <(jq -r '.[]' <<<"$feed_sources_json")

echo
 echo "-- notifier dry run --"
if "${ROOT_DIR}/scripts/notify.sh" "x-user-watch doctor" "delivery check" "https://example.com"; then
  echo "[ OK ] notify.sh executed"
else
  echo "[FAIL] notify.sh failed"
fi
