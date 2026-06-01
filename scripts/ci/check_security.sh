#!/bin/bash
set -euo pipefail

python3 - <<'PY'
import json
import sys
import urllib.error
import urllib.request

specs = []
for line in open('Gemfile.lock', encoding='utf-8'):
    item = line.strip()
    if not item or ' (' not in item:
        continue
    if item.startswith('moose-inventory'):
        continue
    name = item.split(' (', 1)[0]
    version = item.split(' (', 1)[1].split(')', 1)[0].split('-', 1)[0]
    if name and name[0].isalpha():
        specs.append((name, version))

queries = [
    {'package': {'name': name, 'ecosystem': 'RubyGems'}, 'version': version}
    for name, version in specs
]

request = urllib.request.Request(
    'https://api.osv.dev/v1/querybatch',
    data=json.dumps({'queries': queries}).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
)

try:
    with urllib.request.urlopen(request, timeout=30) as response:
        data = json.load(response)
except (urllib.error.URLError, TimeoutError) as exc:
    print(f'OSV dependency check failed: {exc}', file=sys.stderr)
    sys.exit(2)

findings = []
for (name, version), result in zip(specs, data.get('results', [])):
    for vuln in result.get('vulns') or []:
        findings.append((name, version, vuln.get('id', 'unknown'), vuln.get('summary') or ''))

print(f'OSV dependency check: queried={len(specs)} vulnerable={len(findings)}')
if findings:
    for name, version, vuln_id, summary in findings:
        print(f'- {name} {version}: {vuln_id} {summary}', file=sys.stderr)
    sys.exit(1)
PY

bundle exec bundle-audit check --update

BIN_DIR="${MOOSE_INVENTORY_SECURITY_TOOLS_BIN:-$PWD/tmp/security-tools/bin}"
if command -v osv-scanner >/dev/null 2>&1; then
  OSV_SCANNER=(osv-scanner)
elif [ -x "$BIN_DIR/osv-scanner" ]; then
  OSV_SCANNER=("$BIN_DIR/osv-scanner")
else
  if [ "${MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS:-0}" = "1" ]; then
    echo "osv-scanner is required but was not found. Run scripts/ci/install_security_tools.sh first." >&2
    exit 2
  fi
  echo "osv-scanner not found; skipping osv-scanner lockfile scan."
  exit 0
fi

# osv-scanner 2.x treats --lockfile as an explicit scan target; adding the
# repository path as a positional source makes it try to infer an extractor for
# Gemfile.lock through the directory scanner and fail with exit 127.
"${OSV_SCANNER[@]}" scan source --lockfile Gemfile.lock
