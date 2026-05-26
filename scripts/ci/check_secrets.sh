#!/bin/bash
set -euo pipefail

BIN_DIR="${MOOSE_INVENTORY_SECURITY_TOOLS_BIN:-$PWD/tmp/security-tools/bin}"
if command -v gitleaks >/dev/null 2>&1; then
  GITLEAKS=(gitleaks)
elif [ -x "$BIN_DIR/gitleaks" ]; then
  GITLEAKS=("$BIN_DIR/gitleaks")
else
  if [ "${MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS:-0}" = "1" ]; then
    echo "gitleaks is required but was not found. Run scripts/ci/install_security_tools.sh first." >&2
    exit 2
  fi
  echo "gitleaks not found; skipping dedicated secret scan."
  exit 0
fi

"${GITLEAKS[@]}" detect \
  --no-git \
  --source . \
  --config .gitleaks.toml \
  --redact \
  --no-banner \
  --log-level warn

echo "Gitleaks secret scan passed."
