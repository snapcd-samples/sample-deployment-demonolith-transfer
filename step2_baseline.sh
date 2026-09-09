#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source .env

# Establish the world the transfer starts from: the four living roots the
# split left behind, each applied into its own remote state, each planning
# clean. The clean plans are the prerequisite demonolith documents — drift
# is ruled out here, not by the transfer. The snapcd root is applied later,
# once a Snap CD server is running (see the README's closing section).
for root in networking cluster database app; do
  echo "== $root"
  tofu -chdir="roots/$root" init -input=false
  tofu -chdir="roots/$root" apply -auto-approve -input=false
  tofu -chdir="roots/$root" plan -detailed-exitcode -input=false >/dev/null
done
echo "-----------"
echo "Baseline established: four roots applied, all planning clean."
