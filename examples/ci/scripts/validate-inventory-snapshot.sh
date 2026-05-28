#!/usr/bin/env bash
set -euo pipefail

snapshot="${1:-examples/ci/inventory/example-snapshot.yml}"
artifact_dir="${2:-tmp/inventory-ci-artifacts}"
moose_cmd="${MOOSE_INVENTORY_CMD:-moose-inventory}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$artifact_dir"
config_file="$work_dir/moose-inventory-ci.yml"
db_file="$work_dir/inventory.db"

cat > "$config_file" <<YAML
---
general:
  defaultenv: ci
ci:
  db:
    adapter: sqlite3
    file: "$db_file"
YAML

$moose_cmd --config "$config_file" --env ci import "$snapshot"
$moose_cmd --config "$config_file" --env ci doctor > "$artifact_dir/doctor.txt"
$moose_cmd --config "$config_file" --env ci --format yaml export "$artifact_dir/inventory.yml"
$moose_cmd --config "$config_file" --env ci --format pjson host list > "$artifact_dir/hosts.json"
$moose_cmd --config "$config_file" --env ci --ansible group list > "$artifact_dir/ansible-inventory.json"

echo "Inventory CI artifacts written to $artifact_dir"
