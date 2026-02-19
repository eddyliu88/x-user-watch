---
name: x-user-watch
description: Monitor one or more public X/Twitter handles via RSS and send new-post alerts to one or more channels (Telegram, Slack webhook, ntfy, Gotify, or generic webhook) without using LLM calls. Use when users want low-cost feed watching, multi-channel notifications, and simple shell-based automation.
---

# x-user-watch

`x-user-watch` is a shell skill for public X feeds.

It does three things:
1. Read handles from `config.json`
2. Check latest RSS item per handle
3. Notify configured channels when there is a new item

## Run

```bash
bash scripts/watch.sh --once
bash scripts/watch.sh --daemon
```

## Manage handles

```bash
bash scripts/handles.sh list
bash scripts/handles.sh add realdonaldtrump
bash scripts/handles.sh remove realdonaldtrump
```

## Manage notifier channels

```bash
bash scripts/notifiers.sh list
bash scripts/notifiers.sh remove 0
```

If no notifier channels exist, watcher exits and does not keep polling.

## Storage

- Runtime config: `config.json`
- Last-seen IDs: `data/state.json`

## Limits

- Public accounts only
- Depends on RSS mirror availability
