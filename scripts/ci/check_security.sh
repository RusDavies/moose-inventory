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
