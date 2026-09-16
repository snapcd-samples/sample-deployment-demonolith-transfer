#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# The second transfer. Months later (or minutes, here) you notice the next
# misplaced resource: the backup suffix belongs in database. Mark it - one
# comment above the block - and run the same code half again with the new
# receiver. The variable and local it reads travel with it; its depends_on
# on the DNS id became a snapcd_depends_on_module in the first transfer.
if ! grep -B1 'resource "random_id" "backup_suffix"' roots/app/main.tf | grep -q '@demono:transfer'; then
  sed -i 's|^resource "random_id" "backup_suffix" {|# @demono:transfer\nresource "random_id" "backup_suffix" {|' roots/app/main.tf
  echo 'Marked random_id.backup_suffix with # @demono:transfer'
fi

demonolith transfer refactor -y --transfer-target ../database --root-dir roots/app

echo "-----------"
echo "Second code move done. Run ./step4_migrate.sh again to move its state."
