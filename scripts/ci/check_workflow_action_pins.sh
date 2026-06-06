#!/bin/bash
set -euo pipefail

workflow_dir=".github/workflows"

if [ ! -d "$workflow_dir" ]; then
  exit 0
fi

failures=0

while IFS= read -r -d '' workflow; do
  while IFS=: read -r line_no uses_ref; do
    # Skip empty parser output.
    [ -n "$uses_ref" ] || continue

    # Local reusable actions are repository content, not remote moving refs.
    if [[ "$uses_ref" == ./* ]]; then
      continue
    fi

    if [[ ! "$uses_ref" =~ @[0-9a-fA-F]{40}$ ]]; then
      echo "$workflow:$line_no uses '$uses_ref', which is not pinned to a full 40-character commit SHA" >&2
      failures=1
    fi
  done < <(ruby -ne 'if $_ =~ /^\s*uses:\s*([^\s#]+)/; puts "#{$.}:#{$1}"; end' "$workflow")
done < <(find "$workflow_dir" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)

if [ "$failures" -ne 0 ]; then
  echo "GitHub Actions workflow uses entries must be pinned to immutable commit SHAs." >&2
  exit 1
fi
