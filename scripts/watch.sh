#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.json"
STATE_PATH="${ROOT_DIR}/data/state.json"
NOTIFY_SCRIPT="${ROOT_DIR}/scripts/notify.sh"

if [[ ! -f "$CONFIG_PATH" ]]; then
  cp "${ROOT_DIR}/config.example.json" "$CONFIG_PATH"
  echo "Created config.json from config.example.json"
fi
mkdir -p "$(dirname "$STATE_PATH")"
[[ -f "$STATE_PATH" ]] || echo '{}' > "$STATE_PATH"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

ensure_channels_exist() {
  local count
  count="$(jq -r '(.channels // []) | length' "$CONFIG_PATH")"
  if [[ "$count" -le 0 ]]; then
    echo "No delivery channels configured (channels is empty). Stopping watcher." >&2
    return 1
  fi
}

build_feed_url() {
  local handle="$1"
  local template="$2"
  if [[ "$template" == *"{handle}"* ]]; then
    echo "${template//\{handle\}/$handle}"
  else
    echo "${template%/}/${handle}/rss"
  fi
}

fetch_latest_item() {
  local handle="$1"
  local source_template="$2"
  local feed_url
  feed_url="$(build_feed_url "$handle" "$source_template")"

  local feed item
  if ! feed="$(curl -fsSL "$feed_url")"; then
    echo "WARN: failed to fetch RSS for @$handle from $feed_url" >&2
    return 1
  fi

  if [[ -z "$feed" ]]; then
    echo "WARN: empty RSS response for @$handle from $feed_url" >&2
    return 1
  fi

  if ! grep -qiE '<rss|<feed' <<<"$feed"; then
    echo "WARN: non-RSS response for @$handle from $feed_url (likely anti-bot/challenge page)" >&2
    return 1
  fi

  item="$(awk 'BEGIN{RS="</item>"}/<item>/{print; exit}' <<<"$feed")"
  if [[ -z "$item" ]]; then
    echo "WARN: RSS has no <item> for @$handle from $feed_url" >&2
    return 1
  fi

  local guid title link
  guid="$(printf '%s' "$item" | sed -n 's:.*<guid[^>]*>\(.*\)</guid>.*:\1:p' | head -n1)"
  title="$(printf '%s' "$item" | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | head -n1 | sed 's/&quot;/"/g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g')"
  link="$(printf '%s' "$item" | sed -n 's:.*<link>\(.*\)</link>.*:\1:p' | head -n1)"

  [[ -n "$guid" ]] || {
    echo "WARN: could not parse GUID for @$handle from $feed_url" >&2
    return 1
  }
  printf '%s\t%s\t%s\n' "$guid" "$title" "$link"
}

check_once() {
  local handles_json
  handles_json="$(jq -c '.handles' "$CONFIG_PATH")"

  local feed_sources_json
  feed_sources_json="$(jq -c '
    if (.rss_templates // null) != null then .rss_templates
    elif (.rss_bases // null) != null then .rss_bases
    else [(.rss_base // "https://nitter.net")]
    end
  ' "$CONFIG_PATH")"

  local tmp_state
  tmp_state="$(mktemp)"
  cp "$STATE_PATH" "$tmp_state"

  local changed=0
  while IFS= read -r handle; do
    [[ -n "$handle" ]] || continue

    result=""
    while IFS= read -r src; do
      [[ -n "$src" ]] || continue
      if result="$(fetch_latest_item "$handle" "$src")"; then
        break
      fi
    done < <(jq -r '.[]' <<<"$feed_sources_json")

    if [[ -n "$result" ]]; then
      guid="${result%%$'\t'*}"
      rest="${result#*$'\t'}"
      title="${rest%%$'\t'*}"
      link="${rest#*$'\t'}"

      prev="$(jq -r --arg h "$handle" '.[$h] // ""' "$tmp_state")"
      if [[ "$guid" != "$prev" ]]; then
        "$NOTIFY_SCRIPT" "@$handle posted" "$title" "$link"
        jq --arg h "$handle" --arg id "$guid" '.[$h]=$id' "$tmp_state" > "${tmp_state}.new"
        mv "${tmp_state}.new" "$tmp_state"
        changed=1
      fi
    fi
  done < <(jq -r '.[]' <<<"$handles_json")

  if [[ "$changed" -eq 1 ]]; then
    mv "$tmp_state" "$STATE_PATH"
  else
    rm -f "$tmp_state"
  fi
}

mode="${1:---once}"
poll_seconds="$(jq -r '.poll_seconds // 180' "$CONFIG_PATH")"

case "$mode" in
  --once)
    ensure_channels_exist || exit 1
    check_once
    ;;
  --daemon)
    while true; do
      ensure_channels_exist || exit 1
      check_once || true
      sleep "$poll_seconds"
    done
    ;;
  *)
    echo "Usage: bash scripts/watch.sh --once|--daemon" >&2
    exit 1
    ;;
esac
