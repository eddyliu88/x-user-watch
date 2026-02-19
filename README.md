# x-user-watch

A tiny X/Twitter watcher for OpenClaw users.

It watches multiple handles and sends alerts when a new post appears.
No LLM calls. No token burn.

## Features

- Multiple handles
- Deduped alerts (by latest post ID)
- Low resource usage
- Notification targets:
  - Telegram
  - Slack webhook
  - ntfy
  - Gotify
  - generic webhook

## Quick start

```bash
cp config.example.json config.json
# edit config.json
bash scripts/watch.sh --once
bash scripts/watch.sh --daemon
```

Handle management helper:

```bash
bash scripts/handles.sh list
bash scripts/handles.sh add realdonaldtrump
bash scripts/handles.sh remove realdonaldtrump
```

## Dependencies

- `bash`
- `curl`
- `jq`

Ubuntu/Debian:

```bash
sudo apt update && sudo apt install -y curl jq
```

## Config

- `poll_seconds`: check interval
- `rss_base`: RSS mirror base (default `https://nitter.net`)
- `handles`: accounts to watch (without `@`)
- `notifiers`: list of channels to send to (one or many)

Each notifier item must have `type` and matching settings:

- `telegram`: `telegram.bot_token`, `telegram.chat_id`
- `slack`: `slack.webhook_url`
- `ntfy`: `ntfy.url` (+ optional token)
- `gotify`: `gotify.url`, `gotify.token`
- `webhook`: `webhook.url` (+ optional bearer token)

If `notifiers` is missing/empty or any notifier item is invalid, the script exits with a clear error message.

### Multiple channels example

```json
{
  "notifiers": [
    {
      "type": "telegram",
      "telegram": { "bot_token": "<token>", "chat_id": "<chat_id>" }
    },
    {
      "type": "slack",
      "slack": { "webhook_url": "https://hooks.slack.com/services/..." }
    }
  ]
}
```

## Suggested run modes

### systemd (recommended)

Use a simple service with `watch.sh --daemon`.

### cron

Run every minute with `watch.sh --once`.

## Behavior details

- `watch.sh --once` runs one polling cycle.
- `watch.sh --daemon` runs continuously and sleeps for `poll_seconds` between cycles.
- `handles.sh add/remove/list` manages `handles` in `config.json`.
- On first seen handle, current latest post is treated as new and notified, then stored in `data/state.json`.
- Deduping is done per handle using latest GUID from RSS.

## Notes

- This uses public RSS mirrors. If one mirror fails, switch `rss_base`.
- Public accounts only. Protected/private accounts are not available via RSS mirrors.
- For production reliability, prefer running with systemd and restart policy.
