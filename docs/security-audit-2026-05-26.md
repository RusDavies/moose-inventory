# Security audit — 2026-05-26

Scope: local static/security review of the `moose-inventory` Ruby CLI/gem at commit `8c3eaada5d70ef599961b8ca8b78e12ea4ce83c9` on branch `security-audit-2026-05-26`.

## Executive summary

No actionable security vulnerabilities were identified in this pass.

The meaningful attack surface remains local CLI execution, configuration-file loading, database access through Sequel, package/release automation, and developer tooling. There is no HTTP server, RPC endpoint, webhook handler, queue consumer, file upload parser, shell-command execution path, or plugin system in this repository.

The areas remediated in the prior 2026-05-21 audit remain in good shape: YAML config loading uses `YAML.safe_load_file`, DB credentials can be supplied through environment variables, OSV reports no known vulnerable locked RubyGems dependencies, CI/package sanity gates are present, and GitHub Dependabot has no open alerts.

## Surfaces reviewed

- CLI entrypoint: `bin/moose-inventory`
- Global option parsing and config loading: `lib/moose_inventory/config/config.rb`
- DB connection/schema/transaction code: `lib/moose_inventory/db/db.rb`
- Sequel models and associations: `lib/moose_inventory/db/models.rb`
- CLI command handlers under `lib/moose_inventory/cli/`
- Formatter/output serialization: `lib/moose_inventory/cli/formatter.rb`
- Packaging and release metadata: `moose-inventory.gemspec`, `Gemfile`, `Gemfile.lock`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`
- Helper scripts under `scripts/`
- Test config/spec fixtures under `spec/`

## Findings

No P0/P1/P2/P3 actionable findings were identified.

## Notable negative findings

- Config deserialization uses `YAML.safe_load_file` with aliases disabled and no permitted classes/symbols.
- No runtime shell execution sinks were identified.
- Database access uses Sequel model/dataset/hash APIs for user-controlled names, groups, hosts, and variables; no raw SQL interpolation was identified in reviewed runtime paths.
- MySQL/PostgreSQL passwords can be supplied via `password_env`, and README guidance prefers environment-backed passwords over plaintext config values.
- No committed secrets were identified outside expected example/test placeholders.
- GitHub Actions release publishing uses RubyGems trusted publishing/OIDC rather than a stored RubyGems API key.
- Dependency advisory gate queried OSV for 41 locked RubyGems dependency records and reported zero known vulnerabilities.
- GitHub Dependabot open-alert query returned zero open alerts.

## Tooling evidence

- Audit evidence store initialized at `.openclaw-security-audit/audit.sqlite` with `audit_run_id=1`.
- Inventory: 187 files; Ruby manifests detected: `Gemfile`, `Gemfile.lock`, plus generated package-sanity manifests under `tmp/package-sanity`.
- Symbol extractor scanned 156 files but did not extract Ruby symbols/surfaces with the current lightweight extractor.
- Semgrep auto-config failed because metrics are disabled; reran explicit Ruby registry rules instead.
- Semgrep: `semgrep --config p/ruby --json --metrics=off --exclude .openclaw-security-audit --exclude spec/reports --exclude tmp .` scanned 62 tracked Ruby files with 44 rules and returned 0 findings.
- Dependency advisory gate: `./scripts/ci/check_security.sh` queried 41 RubyGems dependencies and returned 0 vulnerable dependencies.
- Full local gate: `./scripts/check.sh` passed with 268 examples, 0 failures, 96.52% line coverage, OSV 0 vulnerabilities, and package sanity passed.
- GitHub Dependabot: `gh api 'repos/RusDavies/moose-inventory/dependabot/alerts?state=open' --jq 'length'` returned `0`.
- GitHub code-scanning alerts could not be queried because no code-scanning analysis exists for this repository; GitHub returned `404 no analysis found`.

## Tooling limitations

- `osv-scanner`, `bundler-audit`/`bundle-audit`, `gitleaks`, `trufflehog`, `brakeman`, `flog`, and `reek` were not installed in this environment.
- `bundle exec rubocop` could not run because RuboCop is not part of the bundle. This is not a security gate failure, but it limits style/static-quality coverage.
- Secret scanning was limited to tracked-file grep patterns because dedicated secret scanners were unavailable.
- The audit did not perform active exploitation against external systems or live database servers.

## Residual risks / recommendations

- Consider adding a dedicated secret scanner such as `gitleaks` or `trufflehog` to local/CI security tooling if this project will accept outside contributions.
- Consider adding `bundler-audit` or `osv-scanner` as an optional developer tool if broader advisory coverage is desired beyond the existing custom OSV gate.
- Keep generated coverage and package-sanity artifacts excluded from security scans; they are noisy and not part of the runtime gem surface.
