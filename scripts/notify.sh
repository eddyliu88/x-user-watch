#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.json"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "config.json not found. Copy config.example.json first." >&2
  exit 1
fi

json_escape() {
  sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

TITLE="${1:-New post}"
BODY="${2:-}"
URL="${3:-}"
MESSAGE="$TITLE\n$BODY\n$URL"

COUNT="$(jq -r '(.notifiers // []) | length' "$CONFIG_PATH")"
[[ "$COUNT" -gt 0 ]] || {
  echo "notifiers is missing or empty in config.json" >&2
  exit 1
}

send_one() {
  local idx="$1"
  local type
  type="$(jq -r ".notifiers[$idx].type // \"\"" "$CONFIG_PATH")"
  [[ -n "$type" ]] || { echo "notifiers[$idx].type is missing" >&2; return 1; }

  case "$type" in
    telegram)
      local bot_token chat_id
      bot_token="$(jq -r ".notifiers[$idx].telegram.bot_token // \"\"" "$CONFIG_PATH")"
      chat_id="$(jq -r ".notifiers[$idx].telegram.chat_id // \"\"" "$CONFIG_PATH")"
      [[ -n "$bot_token" && -n "$chat_id" ]] || { echo "notifiers[$idx]: telegram.bot_token/chat_id missing" >&2; return 1; }
      curl -fsS -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d "chat_id=${chat_id}" \
        --data-urlencode "text=${MESSAGE}" >/dev/null
      ;;

    slack)
      local slack_webhook
      slack_webhook="$(jq -r ".notifiers[$idx].slack.webhook_url // \"\"" "$CONFIG_PATH")"
      [[ -n "$slack_webhook" ]] || { echo "notifiers[$idx]: slack.webhook_url missing" >&2; return 1; }
      curl -fsS -X POST "$slack_webhook" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$(printf '%s' "$MESSAGE" | json_escape)\"}" >/dev/null
      ;;

    ntfy)
      local ntfy_url ntfy_token
      ntfy_url="$(jq -r ".notifiers[$idx].ntfy.url // \"\"" "$CONFIG_PATH")"
      ntfy_token="$(jq -r ".notifiers[$idx].ntfy.token // \"\"" "$CONFIG_PATH")"
      [[ -n "$ntfy_url" ]] || { echo "notifiers[$idx]: ntfy.url missing" >&2; return 1; }
      if [[ -n "$ntfy_token" ]]; then
        curl -fsS -X POST "$ntfy_url" -H "Authorization: Bearer $ntfy_token" -d "$MESSAGE" >/dev/null
      else
        curl -fsS -X POST "$ntfy_url" -d "$MESSAGE" >/dev/null
      fi
      ;;

    gotify)
      local gotify_url gotify_token
      gotify_url="$(jq -r ".notifiers[$idx].gotify.url // \"\"" "$CONFIG_PATH")"
      gotify_token="$(jq -r ".notifiers[$idx].gotify.token // \"\"" "$CONFIG_PATH")"
      [[ -n "$gotify_url" && -n "$gotify_token" ]] || { echo "notifiers[$idx]: gotify.url/token missing" >&2; return 1; }
      curl -fsS -X POST "$gotify_url?token=$gotify_token" \
        -H 'Content-Type: application/json' \
        -d "{\"title\":\"$(printf '%s' "$TITLE" | json_escape)\",\"message\":\"$(printf '%s' "$BODY\n$URL" | json_escape)\",\"priority\":5}" >/dev/null
      ;;

    webhook)
      local webhook_url bearer payload
      webhook_url="$(jq -r ".notifiers[$idx].webhook.url // \"\"" "$CONFIG_PATH")"
      bearer="$(jq -r ".notifiers[$idx].webhook.bearer_token // \"\"" "$CONFIG_PATH")"
      [[ -n "$webhook_url" ]] || { echo "notifiers[$idx]: webhook.url missing" >&2; return 1; }
      payload="{\"title\":\"$(printf '%s' "$TITLE" | json_escape)\",\"body\":\"$(printf '%s' "$BODY" | json_escape)\",\"url\":\"$(printf '%s' "$URL" | json_escape)\"}"
      if [[ -n "$bearer" ]]; then
        curl -fsS -X POST "$webhook_url" -H "Authorization: Bearer $bearer" -H 'Content-Type: application/json' -d "$payload" >/dev/null
      else
        curl -fsS -X POST "$webhook_url" -H 'Content-Type: application/json' -d "$payload" >/dev/null
      fi
      ;;

    *)
      echo "notifiers[$idx]: unsupported type '$type' (supported: telegram|slack|ntfy|gotify|webhook)" >&2
      return 1
      ;;
  esac
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
