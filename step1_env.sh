#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Creates the local session file from its committed .sample counterpart, if
# it doesn't exist yet. Later steps load .env themselves.
[ -f .env ] || cp .env.sample .env

echo "-----------"
echo "Session file ready: .env"
