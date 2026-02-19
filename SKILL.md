---
name: x-user-watch
description: Watch one or more X/Twitter accounts and send notifications when they post. Use for low-cost feed monitoring with no LLM calls. Supports Telegram, ntfy, Gotify, and generic webhooks.
---

# x-user-watch

This skill is a lightweight watcher.

- No agent loop
- No model calls
- Just polling + notify

## What it does

1. Read `config.json`
2. Pull each handle's RSS feed
3. Compare latest item with local state
4. Send notification if there's a new post
5. Save new state

## Setup

1. Copy `config.example.json` to `config.json`
2. Fill in your handles and notifier settings
3. Run once:

```bash
bash scripts/watch.sh --once
```

4. Run continuously:

```bash
bash scripts/watch.sh --daemon
```

Or use cron/systemd and call `--once`.

## Notes

- Uses RSS source (`nitter.net` by default)
- If one RSS mirror is blocked in your region, swap `rss_base` in config
- State is stored in `data/state.json`
