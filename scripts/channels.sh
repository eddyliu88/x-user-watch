#!/usr/bin/env bash
set -euo pipefail

# Backward-compatible alias: channels.sh is the preferred name.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/notifiers.sh" "$@"
