#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source .env

# The state half, one root at a time: pull each state read-only and pin it,
# prove the move offline (app, networking and database all plan to zero
# changes against moved local copies, with networking's output threaded
# into app's new input — exactly what Snap CD does at runtime), then
# rewrite the receivers' states first and the source root's last, and
# verify against the real store. Idempotent: a crashed run is retried by
# just re-running.
#
# --all runs every root's slice from here because all of them share this
# checkout. Roots on separate machines each run `demonolith transfer
# migrate` themselves, passing the fragment, output-value, and run-receipt
# files in their .demono-transfer directories between them.
demonolith transfer migrate --all -y --engine tofu --root-dir roots/app
