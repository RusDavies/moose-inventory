# Security audit — 2026-05-21

Scope: local static/security review of the `moose-inventory` Ruby CLI/gem at commit `ff522502d5981314c451e855be10cbbc7ebeba48`, plus the hardening changes on branch `security-audit-2026-05-21`.

## Executive summary

The audit found one actionable dependency vulnerability and one low-risk repository hygiene issue. Both were remediated in this branch:

1. Development dependency `rake 10.5.0` was affected by CVE-2020-8130 / GHSA-jppv-gw3r-w3q8, an OS command injection issue in `Rake::FileList` for filenames beginning with `|`. The gemspec now requires `rake >= 13.0, < 14`, and `Gemfile.lock` resolves `rake 13.4.2`.
2. Most source, config, docs, and spec files were executable (`100755`) even though they are not entrypoints. The branch normalizes non-executable files to `100644`, keeping only `bin/moose-inventory` and actual scripts executable.

After the dependency update, an OSV query for locked RubyGems dependencies returned zero known vulnerabilities. Semgrep Ruby rules returned zero findings.

## Surfaces reviewed

- CLI entrypoint: `bin/moose-inventory`
- Global config parsing and file loading: `lib/moose_inventory/config/config.rb`
- DB connection and schema creation: `lib/moose_inventory/db/db.rb`
- Sequel models and associations: `lib/moose_inventory/db/models.rb`
- CLI command handlers under `lib/moose_inventory/cli/`
- Packaging metadata: `moose-inventory.gemspec`, `Gemfile`, `Gemfile.lock`
- Helper scripts under `scripts/`
- Test fixtures/config under `spec/`

## Findings fixed

### P2 — Vulnerable development dependency: `rake 10.5.0`

- Evidence: `Gemfile.lock` resolved `rake (10.5.0)` and `moose-inventory.gemspec` constrained rake to `~> 10`.
- Advisory: OSV/GitHub Advisory `GHSA-jppv-gw3r-w3q8`, CVE-2020-8130.
- Impact: local OS command injection in vulnerable Rake versions when `Rake::FileList` receives a filename beginning with the pipe character (`|`). This is primarily a developer/build-time risk, not a runtime CLI inventory risk.
- Fix: changed the development dependency to `rake >= 13.0, < 14` and refreshed `Gemfile.lock` to `rake 13.4.2`.
- Validation: OSV query after the update returned `deps_with_vulns 0`.

### P4 — Over-broad executable bits on repository files

- Evidence: file inventory showed `100755` executable mode on `Gemfile`, `README.md`, library files, specs, config, and other non-entrypoint files.
- Impact: low. This does not create a direct vulnerability by itself, but it expands accidental execution surface and makes packaging/review noisier than necessary. Tiny footgun, sharp enough to remove.
- Fix: normalized non-entrypoint files to `100644`; retained executable mode for `bin/moose-inventory` and scripts with shebangs.

## Notable negative findings

- Config deserialization now uses `YAML.safe_load_file` with aliases disabled and no permitted classes/symbols.
- No shell execution sinks were found in runtime code. The backtick use in `moose-inventory.gemspec` is the normal `git ls-files` packaging pattern.
- Database access uses Sequel model/hash APIs for user-provided names and variables; no raw SQL interpolation was identified in the reviewed CLI/database paths.
- No committed secrets were identified outside expected example/test placeholder passwords.
- No external network-facing service, HTTP route, RPC handler, webhook, queue consumer, or upload parser exists in this repo; the meaningful attack surface is local CLI usage and build/development tooling.

## Tooling evidence

- Inventory: 79 files; Ruby manifests: `Gemfile`, `Gemfile.lock`.
- Semgrep: `semgrep --config p/ruby --json --quiet .` returned 0 findings.
- OSV dependency query before fix: 1 vulnerable dependency (`rake 10.5.0`, `GHSA-jppv-gw3r-w3q8`).
- OSV dependency query after fix: 41 RubyGems dependency records queried, 0 dependencies with known vulnerabilities.
- `bundle-audit`, `osv-scanner`, `gitleaks`, `trufflehog`, and `brakeman` were not installed in this environment. Brakeman is also Rails-specific and not expected to apply here.

## Residual risks / future hardening

- Consider adding a CI security job for OSV or bundler-audit so dependency advisories are caught before they fossilize in the lockfile like a tiny Jurassic Park exhibit.
- Consider keeping generated coverage artifacts out of normal grep/scanner paths; they are ignored from this audit because they contain large bundled HTML/CSS assets.

## GitHub Dependabot follow-up after first push

After pushing the audit remediation, GitHub emitted a default-branch warning for 7 Dependabot vulnerabilities. Querying the repository Dependabot alerts through `gh api repos/RusDavies/moose-inventory/dependabot/alerts` showed that all 7 were already in `fixed` state after the modernization/security-audit commits reached GitHub:

- `rake`: GHSA-jppv-gw3r-w3q8 / CVE-2020-8130, fixed by `rake >= 13.0, < 14` and lockfile `rake 13.4.2`.
- `json`: GHSA-jphg-qwrw-7w9g / CVE-2020-10663, fixed by the existing current constraint `json >= 2.7, < 3` and lockfile `json 2.19.5`.
- `rubocop`: GHSA-wmjf-jpjj-9f3j / CVE-2017-8418, fixed by removing RuboCop as a development dependency.
- `bundler`: GHSA-jvgm-pfqv-887x / CVE-2016-7954, GHSA-g98m-96g9-wfjq / CVE-2019-3881, GHSA-fp4w-jxhp-m23p / CVE-2020-36327, and GHSA-fj7f-vq84-fh43 / CVE-2021-43809. GitHub marked these fixed because the lockfile uses Bundler 2.6.9; this follow-up also tightens the gemspec development dependency to `bundler >= 2.2.33, < 3` so fresh development installs cannot select known-vulnerable Bundler 1.x/early 2.x releases.

Follow-up validation: `gh api 'repos/RusDavies/moose-inventory/dependabot/alerts?state=open'` returned no open alerts.
