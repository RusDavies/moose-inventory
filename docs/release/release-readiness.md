# Release readiness notes

This project now has a small release-readiness gate intended to catch the regressions found during the modernization and security-audit passes.

## Local gate

Run:

```bash
./scripts/check.sh
```

The gate currently runs:

1. RSpec with coverage via the existing spec helper.
2. `git diff --check` for whitespace/conflict-marker issues in the working tree.
3. `scripts/ci/check_permissions.sh` to ensure only intentional tracked repository entrypoints are executable.
4. `scripts/ci/check_security.sh` to query OSV for locked RubyGems dependency advisories.
5. `scripts/ci/package_sanity.sh` to build the gem, inspect the packaged payload, and smoke-test the CLI version command.

## CI gate

GitHub Actions workflow: `.github/workflows/ci.yml`.

It installs native headers needed by the DB gems, uses Ruby 3.4, relies on Bundler caching, and runs the same `./scripts/check.sh` gate used locally.

## Package sanity expectations

`package_sanity.sh` validates that the built gem includes at least:

- `bin/moose-inventory`
- `lib/moose_inventory.rb`
- `lib/moose_inventory/version.rb`
- `README.md`
- `LICENSE.txt`

It also verifies the gem metadata exposes the `moose-inventory` executable and that `ruby -Ilib bin/moose-inventory version` returns a version string.

## Dependency advisory expectations

`check_security.sh` reads `Gemfile.lock`, queries OSV's batch API for RubyGems packages, and fails on known vulnerabilities. This is intentionally simple and external-network-dependent; if OSV is unavailable, the gate fails closed so CI does not silently bless an unknown dependency state.
