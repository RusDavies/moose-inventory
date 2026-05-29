# Release readiness notes

This project now has a small release-readiness gate intended to catch the regressions found during the modernization and security-audit passes.

Reusable QA, documentation-QA, release, security, accepted-risk, rollback, and post-release templates live in `docs/qa/qa-documentation-and-release-gates.md`.

Routine package maintenance and AI-agent operation boundaries live in `docs/maintenance/package-maintenance-and-agent-boundaries.md`.

## Local gate

Run:

```bash
./scripts/check.sh
```

The gate currently runs:

1. RSpec with coverage via the existing spec helper.
2. `scripts/ci/check_rubocop.sh` for targeted Ruby style/lint checks.
3. `git diff --check` for whitespace/conflict-marker issues in the working tree.
4. `scripts/ci/check_permissions.sh` to ensure only intentional tracked repository entrypoints are executable.
5. `scripts/ci/check_security.sh` to query OSV, run `bundler-audit`, and run `osv-scanner` when available or required.
6. `scripts/ci/check_secrets.sh` to run the dedicated `gitleaks` secret scan when available or required.
7. `scripts/ci/package_sanity.sh` to build the gem, inspect the packaged payload, and smoke-test the CLI version command.

For release evidence, prefer:

```bash
MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
```

## CI gate

GitHub Actions workflow: `.github/workflows/ci.yml`.

It installs native headers needed by the DB gems, runs the same `./scripts/check.sh` gate used locally, and tests the maintained Ruby version range through the GitHub Actions matrix.

## Trusted publishing gate

GitHub Actions workflow: `.github/workflows/release.yml`.

The release workflow runs when a `v*` tag is pushed. It:

1. Checks out the repository using `actions/checkout@v5`.
2. Installs Ruby and native database build dependencies.
3. Fails if the tag version does not match `Moose::Inventory::VERSION`.
4. Runs the full local `./scripts/check.sh` gate.
5. Publishes the gem with `rubygems/release-gem@v1` using RubyGems trusted publishing/OIDC.

RubyGems has a trusted publisher configured for repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`, so the workflow can request a short-lived publish token when a real release tag is pushed.

Current GitHub `release` environment protection evidence is recorded in `docs/release/release-environment-protection.md`. As of 2026-05-29, the environment requires review by `RusDavies`, has self-review prevention disabled, disables admin bypass, and has a custom deployment policy named `v*`. Self-review prevention is disabled because OpenClaw/automation pushes use Russ's GitHub account, and `RusDavies` is currently the only required reviewer. Because GitHub reports the custom deployment policy object as `type: branch`, verify tag-deployment behavior on the next real release and adjust the environment policy if needed.

This path was verified with release `v2.0` / gem `2.0`: RubyGems trusted publishing succeeded and the published gem was installable afterward. The release workflow now disables `rubygems/release-gem`'s post-publish await step (`await-release: false`) because RubyGems full-index propagation lag produced false-negative workflow failures even after successful publishes.

Package provenance hardening beyond trusted publishing is evaluated in `docs/release/package-provenance-hardening.md`. The current release-readiness gate does not require additional checksums, GitHub artifact attestations, detached signatures, RubyGems certificate signing, or SBOM publication unless a future consumer or policy requirement explicitly adds that work.

## Package sanity expectations

`package_sanity.sh` validates that the built gem includes at least:

- `bin/moose-inventory`
- `lib/moose_inventory.rb`
- `lib/moose_inventory/version.rb`
- `README.md`
- `LICENSE.txt`

It also verifies the gem metadata exposes the `moose-inventory` executable and that `bundle exec ruby -Ilib bin/moose-inventory --config spec/config/config.yml version` returns a version string.

## Dependency advisory expectations

`check_security.sh` reads `Gemfile.lock`, queries OSV's batch API for RubyGems packages, and fails on known vulnerabilities. This is intentionally simple and external-network-dependent; if OSV is unavailable, the gate fails closed so CI does not silently bless an unknown dependency state.
