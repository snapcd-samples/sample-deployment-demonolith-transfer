#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# The code half: analyze the decorated app root, write the transfer map,
# move the blocks — they leave app's files and land in networking's and
# database's own main.tf/variables.tf/outputs.tf, with the Snap CD wiring
# appended to roots/snapcd/main.tf (found as app's sibling named "snapcd")
# — and gate the result with `transfer refactor diff --all`. Nothing
# touches any state.
#
# The finalized map is copied into every touched root, so each root carries
# the whole transfer and can gate its own files with a bare `transfer
# refactor diff` run against it — no other roots checked out. That per-root
# gate is what the CI workflow's slice-diff lane runs.
#
# From committing this until step4 completes, app, networking and database
# plan dirty: in a real setup this is where their pipelines freeze. The
# cluster root is untouched and keeps living normally.
demonolith transfer refactor -y --root-dir roots/app
