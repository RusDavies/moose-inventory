#!/bin/bash
set -euo pipefail

pkg_dir="tmp/pkg"
extract_dir="tmp/package-sanity"
rm -rf "$pkg_dir" "$extract_dir"
mkdir -p "$pkg_dir" "$extract_dir"

gem_path="$pkg_dir/moose-inventory.gem"
gem build moose-inventory.gemspec --output "$gem_path"

gem specification "$gem_path" name --yaml > "$pkg_dir/name.yml"
gem specification "$gem_path" version --yaml > "$pkg_dir/version.yml"
gem specification "$gem_path" executables --yaml > "$pkg_dir/executables.yml"
gem specification "$gem_path" require_paths --yaml > "$pkg_dir/require_paths.yml"
gem specification "$gem_path" files --yaml > "$pkg_dir/files.yml"

tar -xf "$gem_path" -C "$extract_dir"
tar -xzf "$extract_dir/data.tar.gz" -C "$extract_dir"

required_files=(
  "bin/moose-inventory"
  "lib/moose_inventory.rb"
  "lib/moose_inventory/version.rb"
  "README.md"
  "LICENSE.txt"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$extract_dir/$path" ]]; then
    echo "Packaged gem is missing required file: $path" >&2
    exit 1
  fi
done

if ! grep -q "^- moose-inventory$" "$pkg_dir/executables.yml"; then
  echo "Packaged gem metadata does not expose the moose-inventory executable." >&2
  exit 1
fi

if ! ruby -Ilib bin/moose-inventory --config spec/config/config.yml version | grep -q '^Version '; then
  echo "CLI version smoke failed." >&2
  exit 1
fi

printf 'Package sanity passed: %s\n' "$gem_path"
