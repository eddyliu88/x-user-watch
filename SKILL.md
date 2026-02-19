---
name: x-user-watch
description: Monitor one or more public X/Twitter handles via RSS and send new-post alerts through OpenClaw chat channels using openclaw message send (telegram, whatsapp, discord, slack, signal, etc.) without LLM calls.
---

# x-user-watch

`x-user-watch` is a shell skill for public X feeds.

It does three things:
1. Read handles from `config.json`
2. Check latest RSS item per handle
3. Send alerts through configured OpenClaw channels

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

## Manage delivery channels

```bash
bash scripts/channels.sh list
bash scripts/channels.sh add telegram 1250920101 default
bash scripts/channels.sh remove 0
```

If no delivery channels exist, watcher exits and does not keep polling.

## Storage

- Runtime config: `config.json`
- Last-seen IDs: `data/state.json`

## Limits

- Public accounts only
- Depends on RSS mirror availability
