#!/bin/bash
set -euo pipefail

allowed_executables=(
  "bin/moose-inventory"
  "scripts/check.sh"
  "scripts/ci/check_permissions.sh"
  "scripts/ci/check_rubocop.sh"
  "scripts/ci/check_secrets.sh"
  "scripts/ci/check_security.sh"
  "scripts/ci/install_security_tools.sh"
  "scripts/ci/package_sanity.sh"
  "scripts/files.rb"
  "scripts/install_dependencies.sh"
  "scripts/reports.sh"
  "scripts/work-through.sh"
)

allowed_file="$(mktemp)"
actual_file="$(mktemp)"
trap 'rm -f "$allowed_file" "$actual_file"' EXIT

printf '%s\n' "${allowed_executables[@]}" | sort > "$allowed_file"

git ls-files -z | while IFS= read -r -d '' path; do
  if [[ -x "$path" ]]; then
    printf '%s\n' "$path"
  fi
done | sort > "$actual_file"

if ! diff -u "$allowed_file" "$actual_file"; then
  echo "Unexpected executable file permissions detected." >&2
  echo "Update scripts/ci/check_permissions.sh only when a new executable entrypoint is intentional." >&2
  exit 1
fi
