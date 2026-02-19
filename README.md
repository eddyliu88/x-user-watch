# x-user-watch

Watch public X/Twitter accounts and push alerts when a new post appears.

No LLM loop. This is plain shell polling + notifications.

## What this is good for

- Track multiple handles
- Send alerts to one or more channels
- Keep cost near zero (no model calls)

## What this is not

- Private/protected account monitoring
- Guaranteed real-time delivery (depends on polling interval + RSS source)

## Features

- Multi-handle watchlist
- Deduped alerts using latest item GUID per handle
- Multi-channel notifications (`notifiers[]`)
- Handle management helper
- Notifier management helper
- Clear config errors

## Dependencies

- `bash`
- `curl`
- `jq`

Ubuntu/Debian:

```bash
sudo apt update && sudo apt install -y curl jq
```

## Quick start

```bash
cp config.example.json config.json
# edit config.json
bash scripts/watch.sh --once
bash scripts/watch.sh --daemon
```

## Config

Main fields:

- `poll_seconds`: check interval (default 60)
- `rss_base`: RSS mirror base (`https://nitter.net` by default)
- `handles`: list of accounts without `@`
- `notifiers`: list of delivery channels (one or many)

Notifier types:

- `telegram`: `telegram.bot_token`, `telegram.chat_id`
- `slack`: `slack.webhook_url`
- `ntfy`: `ntfy.url` (+ optional `ntfy.token`)
- `gotify`: `gotify.url`, `gotify.token`
- `webhook`: `webhook.url` (+ optional `webhook.bearer_token`)

If `notifiers` is empty, the watcher exits immediately (no polling).

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

`remove` uses zero-based index from `list` output.

## Config examples

- `config.example.json` (minimal starter)
- `examples/config.telegram.json`
- `examples/config.multi-channel.json`

## Suggested run modes

### systemd (recommended)

Run `watch.sh --daemon` as a service with restart policy.

### cron

Run `watch.sh --once` every minute.

## Troubleshooting

### `config.json not found`

Create it first:

```bash
cp config.example.json config.json
```

### `notifiers is missing or empty in config.json`

Add at least one notifier in `notifiers[]`.

### `... unsupported type ...`

Allowed values: `telegram|slack|ntfy|gotify|webhook`.

### No alerts even though watcher runs

- Check `handles` is not empty
- Check notifier credentials/webhook are valid
- Test RSS URL manually: `curl "https://nitter.net/<handle>/rss"`

### RSS mirror unstable/blocked

Change `rss_base` to another mirror you trust.

## Migration note (old config)

Old format used a single `notifier` object.
Current format uses `notifiers` array.

Before:

```json
{ "notifier": { "type": "telegram", "telegram": {"bot_token":"...","chat_id":"..."} } }
```

After:

```json
{ "notifiers": [ { "type": "telegram", "telegram": {"bot_token":"...","chat_id":"..."} } ] }
```
