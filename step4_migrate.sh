#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source .env

# The state half of whichever transfer step 3 (or step 5) just mapped, one
# root at a time: pull each state read-only and pin it, prove the move
# offline (source and receiver both plan to zero changes against moved
# local copies, with any moved output threaded into the source's new input
# - exactly what Snap CD does at runtime), then rewrite the receiver's
# state first and the source root's last, and verify against the real
# store. Idempotent: a crashed run is retried by just re-running.
#
# --both runs both roots' parts from here because they share this checkout.
# Roots on separate machines each run `demonolith transfer migrate`
# themselves, passing the fragment, output-value, and run-receipt files in
# their .demono-transfer directories between them.
demonolith transfer migrate --both -y --engine tofu --root-dir roots/app
