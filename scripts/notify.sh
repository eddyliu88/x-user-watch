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

TYPE="$(jq -r '.notifier.type // ""' "$CONFIG_PATH")"
TITLE="${1:-New post}"
BODY="${2:-}"
URL="${3:-}"
MESSAGE="$TITLE\n$BODY\n$URL"

[[ -n "$TYPE" ]] || {
  echo "notifier.type is missing in config.json (set: telegram|slack|ntfy|gotify|webhook)" >&2
  exit 1
}

case "$TYPE" in
  telegram)
    BOT_TOKEN="$(jq -r '.notifier.telegram.bot_token // ""' "$CONFIG_PATH")"
    CHAT_ID="$(jq -r '.notifier.telegram.chat_id // ""' "$CONFIG_PATH")"
    [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]] || { echo "telegram bot_token/chat_id missing" >&2; exit 1; }
    curl -fsS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${MESSAGE}" >/dev/null
    ;;

  slack)
    SLACK_WEBHOOK="$(jq -r '.notifier.slack.webhook_url // ""' "$CONFIG_PATH")"
    [[ -n "$SLACK_WEBHOOK" ]] || { echo "Slack selected but notifier.slack.webhook_url is missing" >&2; exit 1; }
    curl -fsS -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"$(printf '%s' "$MESSAGE" | json_escape)\"}" >/dev/null
    ;;

  ntfy)
    NTFY_URL="$(jq -r '.notifier.ntfy.url // ""' "$CONFIG_PATH")"
    NTFY_TOKEN="$(jq -r '.notifier.ntfy.token // ""' "$CONFIG_PATH")"
    [[ -n "$NTFY_URL" ]] || { echo "ntfy url missing" >&2; exit 1; }
    if [[ -n "$NTFY_TOKEN" ]]; then
      curl -fsS -X POST "$NTFY_URL" -H "Authorization: Bearer $NTFY_TOKEN" -d "$MESSAGE" >/dev/null
    else
      curl -fsS -X POST "$NTFY_URL" -d "$MESSAGE" >/dev/null
    fi
    ;;

  gotify)
    GOTIFY_URL="$(jq -r '.notifier.gotify.url // ""' "$CONFIG_PATH")"
    GOTIFY_TOKEN="$(jq -r '.notifier.gotify.token // ""' "$CONFIG_PATH")"
    [[ -n "$GOTIFY_URL" && -n "$GOTIFY_TOKEN" ]] || { echo "gotify url/token missing" >&2; exit 1; }
    curl -fsS -X POST "$GOTIFY_URL?token=$GOTIFY_TOKEN" \
      -H 'Content-Type: application/json' \
      -d "{\"title\":\"$(printf '%s' "$TITLE" | json_escape)\",\"message\":\"$(printf '%s' "$BODY\n$URL" | json_escape)\",\"priority\":5}" >/dev/null
    ;;

  webhook)
    WEBHOOK_URL="$(jq -r '.notifier.webhook.url // ""' "$CONFIG_PATH")"
    BEARER="$(jq -r '.notifier.webhook.bearer_token // ""' "$CONFIG_PATH")"
    [[ -n "$WEBHOOK_URL" ]] || { echo "webhook url missing" >&2; exit 1; }
    PAYLOAD="{\"title\":\"$(printf '%s' "$TITLE" | json_escape)\",\"body\":\"$(printf '%s' "$BODY" | json_escape)\",\"url\":\"$(printf '%s' "$URL" | json_escape)\"}"
    if [[ -n "$BEARER" ]]; then
      curl -fsS -X POST "$WEBHOOK_URL" -H "Authorization: Bearer $BEARER" -H 'Content-Type: application/json' -d "$PAYLOAD" >/dev/null
    else
      curl -fsS -X POST "$WEBHOOK_URL" -H 'Content-Type: application/json' -d "$PAYLOAD" >/dev/null
    fi
    ;;

  *)
    echo "Unsupported notifier type: $TYPE (supported: telegram|slack|ntfy|gotify|webhook)" >&2
    exit 1
    ;;
esac
