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
- `notifier.type`: `telegram|ntfy|gotify|webhook`

## Suggested run modes

### systemd (recommended)

Use a simple service with `watch.sh --daemon`.

### cron

Run every minute with `watch.sh --once`.

## Notes

- This uses public RSS mirrors. If one mirror fails, switch `rss_base`.
- First run sends notifications for current latest posts unless `data/state.json` is pre-seeded.
