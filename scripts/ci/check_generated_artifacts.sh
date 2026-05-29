#!/bin/bash
set -euo pipefail

# Generated/local artifacts are useful during development but must not become
# source inputs, package contents, or review noise. Keep this list aligned with
# .gitignore and scanner excludes.
generated_paths=(
  ".openclaw-security-audit"
  "coverage"
  "pkg"
  "spec/reports"
  "tmp"
)

tracked=()
for path in "${generated_paths[@]}"; do
  while IFS= read -r file; do
    tracked+=("$file")
  done < <(git ls-files "$path" "$path/**")
done

if (( ${#tracked[@]} > 0 )); then
  echo "Generated artifact paths are tracked and must be removed from source commits:" >&2
  printf '  %s\n' "${tracked[@]}" >&2
  exit 1
fi

ignored_failures=()
for path in "${generated_paths[@]}"; do
  if ! git check-ignore -q "$path/placeholder"; then
    ignored_failures+=("$path/")
  fi
done

if (( ${#ignored_failures[@]} > 0 )); then
  echo "Generated artifact paths are not ignored:" >&2
  printf '  %s\n' "${ignored_failures[@]}" >&2
  exit 1
fi

echo "Generated artifact guard passed."
