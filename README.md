# x-user-watch

Watch public X/Twitter accounts and push alerts when a new post appears.

No LLM loop. This is plain shell polling + notifications.

## What this is good for

- Track multiple handles
- Send alerts to one or more OpenClaw chat channels
- Keep cost near zero (no model calls)

## What this is not

- Private/protected account monitoring
- Guaranteed real-time delivery (depends on polling interval + RSS source)

## Features

- Multi-handle watchlist
- Deduped alerts using latest item GUID per handle
- Multi-channel delivery via `openclaw message send`
- Handle management helper
- Channel route management helper
- Clear config errors

## Dependencies

- `bash`
- `curl`
- `jq`
- `openclaw` CLI

Ubuntu/Debian:

```bash
sudo apt update && sudo apt install -y curl jq
```

## Quick start (minimum working example)

```bash
chmod +x ./x-user-watch
./x-user-watch handles add elonmusk
./x-user-watch channels add telegram 1250920101 default
./x-user-watch watch --once
```

Then run continuously:

```bash
./x-user-watch watch --daemon
```

## Config

Main fields:

- `poll_seconds`: check interval (default 60)
- `rss_base`: RSS mirror base (`https://nitter.net` by default)
- `handles`: list of accounts without `@`
- `channels`: list of OpenClaw delivery routes (one or many)

Each `channels[]` item:

- `channel`: OpenClaw channel slug
- `target`: destination identifier for that channel
- `account_id` (optional): OpenClaw account id (default account used if omitted)

Common `target` formats:

- Telegram DM: numeric chat id (example: `1250920101`)
- WhatsApp: E.164 number (example: `+6281234567890`)
- Slack: channel/user target supported by OpenClaw CLI (example: `channel:C0123456789`)
- Discord: channel target (example: `channel:123456789012345678`)

If `channels` is empty, the watcher exits immediately (no polling).

### Channel example

```json
{
  "channels": [
    {
      "channel": "telegram",
      "target": "1250920101",
      "account_id": "default"
    },
    {
      "channel": "slack",
      "target": "channel:C0123456789"
    }
  ]
}
```

## Supported OpenClaw channels

Use the same channel names supported by your OpenClaw setup, including:

- telegram
- whatsapp
- discord
- irc
- googlechat
- slack
- signal
- imessage
- feishu
- nostr
- msteams
- mattermost
- nextcloud-talk
- matrix
- bluebubbles
- line
- zalo
- zalouser
- tlon

(Availability depends on what the user configured/enabled in OpenClaw.)

## Manage handles

```bash
./x-user-watch handles list
./x-user-watch handles add realdonaldtrump
./x-user-watch handles remove realdonaldtrump
```

Legacy method (still supported): `bash scripts/handles.sh ...`

## Manage delivery channels

```bash
./x-user-watch channels list
./x-user-watch channels add telegram 1250920101 default
./x-user-watch channels remove 0
```

`remove` uses zero-based index from `list` output.

Legacy method (still supported): `bash scripts/channels.sh ...`

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

Run built-in diagnostics:

```bash
./x-user-watch doctor
```

It checks handles/channels config, tests feed sources, and performs a notifier send test.

### `config.json not found`

Scripts auto-create it from `config.example.json` when needed.
If auto-create fails, check file permissions in the skill folder.

### `channels is missing or empty in config.json`

Add at least one channel route in `channels[]`.

### No alerts even though watcher runs

- Check `handles` is not empty
- Check channel route target/account is valid in OpenClaw
- Test RSS URL manually: `curl "https://nitter.net/<handle>/rss"`

### RSS mirror unstable/blocked

Change `rss_base` to another mirror you trust.

## Migration note

Old versions used `notifier` or `notifiers` blocks.
Current version uses `channels` to route through OpenClaw-native messaging.
