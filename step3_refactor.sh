#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# The code half of the first transfer: the blocks marked `# @demono:transfer`
# leave app's files and land in networking's own main.tf/variables.tf/
# outputs.tf, with the Snap CD wiring appended to roots/snapcd/main.tf
# (found as app's sibling named "snapcd") - and the result is gated with
# `transfer refactor diff --both`. Nothing touches any state. The receiver
# is named once, here on the command line.
#
# The finalized map is copied into every touched root, so each root carries
# the whole transfer and can gate its own files with a bare `transfer
# refactor diff` run against it - no other roots checked out. That per-root
# gate is what the CI workflow's slice-diff lane runs.
#
# From committing this until step4 completes, app and networking plan
# dirty: in a real setup this is where their pipelines freeze. The other
# roots are untouched and keep living normally.
demonolith transfer refactor -y --transfer-target ../networking --root-dir roots/app
