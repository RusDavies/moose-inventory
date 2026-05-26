#!/bin/bash
set -euo pipefail

# Installs optional security audit CLIs used by CI. They are kept out of the
# gem runtime/development bundle because they are Go command-line tools, not
# Ruby dependencies.

BIN_DIR="${MOOSE_INVENTORY_SECURITY_TOOLS_BIN:-$PWD/tmp/security-tools/bin}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-v8.30.0}"
OSV_SCANNER_VERSION="${OSV_SCANNER_VERSION:-v2.2.3}"

mkdir -p "$BIN_DIR"

if ! command -v go >/dev/null 2>&1; then
  echo "Go is required to install gitleaks/osv-scanner. Install Go or use a prebuilt package." >&2
  exit 2
fi

install_go_tool() {
  local name="$1"
  local module="$2"
  local version="$3"

  if command -v "$name" >/dev/null 2>&1; then
    echo "$name already available at $(command -v "$name")"
    return
  fi

  if [ -x "$BIN_DIR/$name" ]; then
    echo "$name already installed at $BIN_DIR/$name"
    return
  fi

  echo "Installing $name $version into $BIN_DIR"
  GOBIN="$BIN_DIR" go install "$module@$version"
}

install_go_tool gitleaks github.com/zricethezav/gitleaks/v8 "$GITLEAKS_VERSION"
install_go_tool osv-scanner github.com/google/osv-scanner/v2/cmd/osv-scanner "$OSV_SCANNER_VERSION"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$BIN_DIR" >> "$GITHUB_PATH"
fi

export PATH="$BIN_DIR:$PATH"
gitleaks version || true
osv-scanner --version
