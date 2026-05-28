#!/bin/bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

rubocop_files=(
  Gemfile
  Rakefile
)

while IFS= read -r -d '' file; do
  rubocop_files+=("$file")
done < <(find bin -maxdepth 1 -type f -print0 | sort -z)

while IFS= read -r -d '' file; do
  rubocop_files+=("$file")
done < <(
  find \
    lib \
    scripts \
    spec \
    -path 'spec/reports' -prune -o \
    -path 'spec/reports/*' -prune -o \
    -type f \( -name '*.rb' -o -name '*.gemspec' \) \
    -print0 | sort -z
)

while IFS= read -r -d '' file; do
  rubocop_files+=("$file")
done < <(find . -maxdepth 1 -type f -name '*.gemspec' -print0 | sort -z)

bundle exec rubocop "${rubocop_files[@]}"
