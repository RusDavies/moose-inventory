# Security Audit Rerun — 2026-05-26

Repository: `RusDavies/moose-inventory`  
Local path: `/home/skippy/.openclaw/workspace/projects/moose-inventory`  
Audited commit at start: `a07b5c89214a3cee66170217c5b38e9ad2ae093a`  
Audit branch: `security-audit-2026-05-26-rerun`  
Evidence store: `.openclaw-security-audit/audit.sqlite`, audit run `2`

## Executive summary

The rerun found no exploitable application vulnerabilities in the Ruby CLI/config/database code reviewed, and all deterministic dependency, advisory, package, and secret-scanning gates passed.

One release-supply-chain hardening gap was identified and fixed during the audit: the release workflow ran `./scripts/check.sh` without installing or requiring the dedicated security tools, so a tag-based release could publish even if `gitleaks`, `osv-scanner`, or `bundler-audit` coverage was absent from that release job. CI already enforced those tools; release now does too.

## Scope

Reviewed security-relevant surfaces and changes since the prior audit:

- GitHub Actions CI and release workflows.
- Security-tool installation and enforcement scripts.
- Ruby CLI entrypoints and Thor command surfaces.
- YAML configuration loading.
- SQLite/MySQL/PostgreSQL connection setup and password handling.
- Recursive group deletion behavior touched by recent issue work.
- Gem packaging/release path.

## Deterministic results

- Full local required-tool gate: passed.
  - RSpec: 268 examples, 0 failures.
  - Coverage: 96.52% line coverage.
  - Custom OSV dependency check: 45 dependencies queried, 0 vulnerable.
  - `bundler-audit`: no vulnerabilities found.
  - `osv-scanner`: no issues found in `Gemfile.lock`.
  - `gitleaks`: dedicated secret scan passed.
  - Package sanity: built and inspected `tmp/pkg/moose-inventory.gem` successfully.
- Semgrep Ruby registry scan: 62 tracked Ruby files scanned with 44 Ruby rules, 0 findings.
- GitHub Dependabot open alerts: 0.
- GitHub code scanning alerts: unavailable / no analysis found (`404`).
- GitHub secret scanning alerts: unavailable because secret scanning is disabled for this repository.
- Workflow YAML parse check: `ci.yml` and `release.yml` parsed successfully with Ruby Psych.
- Current GitHub CI before audit branch: latest `master` CI run succeeded for Ruby 3.2, 3.3, and 3.4.

## Finding fixed during audit

### SEC-RERUN-2026-05-26-01 — Release workflow did not require dedicated security tools

- Priority before fix: P2 medium, release supply-chain hardening.
- Exposure: tag-triggered release workflow.
- Affected file: `.github/workflows/release.yml`.
- Evidence: CI installed `gitleaks`/`osv-scanner` and set `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1`, but the release workflow only ran `./scripts/check.sh`. In local mode, `scripts/ci/check_security.sh` and `scripts/ci/check_secrets.sh` intentionally skip missing optional security tools unless `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1` is set.
- Impact: a release tag created from an unexpected commit or during a tooling/path issue could publish without the same dedicated SCA/secret-scan enforcement as CI.
- Fix applied: release workflow now sets up Go with cache disabled, installs the pinned security CLIs via `scripts/ci/install_security_tools.sh`, runs native dependency installation with a 5-minute timeout, and runs `./scripts/check.sh` with `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1`.
- Verification: full local required-tool gate passed after the workflow change.
- Residual risk: release workflow can only be fully proven on the next real release tag because already-published `v1.0.9` must not be retagged.

## Reviewed areas with no actionable finding

- YAML config loading uses `YAML.safe_load_file` with aliases disabled and no permitted classes/symbols.
- SQLite database path handling creates parent directories with `FileUtils.mkdir_p`; this is local config-driven CLI behavior, not a remotely reachable path traversal surface.
- MySQL/PostgreSQL password handling supports `password_env`; plaintext `password` remains for compatibility but README guidance discourages committing it.
- CLI input reaches Sequel model operations rather than shell execution; no shell/eval sink was identified in application code.
- Recent recursive group deletion is explicit opt-in and keeps host fallback behavior covered by regression tests.
- GitHub Actions release job uses OIDC/trusted publishing and does not store a RubyGems API key in the workflow.

## Limitations

- This was a local/source and CI/release workflow audit, not an active test against live external databases or RubyGems publishing.
- GitHub code scanning is not configured, so there were no CodeQL/code-scanning results to review.
- GitHub secret scanning is disabled for the repository; local `gitleaks` coverage was used instead.
- The release trusted-publishing path still needs verification on the next real version tag.

## Conclusion

No open exploitable vulnerabilities remain from this rerun. The only identified security gap was release-pipeline parity with CI security tooling, and it was fixed in this audit branch.
