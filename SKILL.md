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
./x-user-watch watch --once
./x-user-watch watch --daemon
```

## Manage handles

```bash
./x-user-watch handles list
./x-user-watch handles add realdonaldtrump
./x-user-watch handles remove realdonaldtrump
```

## Manage delivery channels

```bash
./x-user-watch channels list
./x-user-watch channels add telegram 1250920101 default
./x-user-watch channels remove 0
```

If no delivery channels exist, watcher exits and does not keep polling.

Legacy script entrypoints remain available under `scripts/`.

## Storage

- Runtime config: `config.json`
- Last-seen IDs: `data/state.json`

## Limits

- Public accounts only
- Depends on RSS mirror availability
