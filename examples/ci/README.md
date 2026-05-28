# Moose Inventory CI/CD Examples

These examples show how to validate an inventory snapshot in CI without using production database credentials.

- `inventory/example-snapshot.yml` is a small review snapshot fixture.
- `scripts/validate-inventory-snapshot.sh` imports a snapshot into a temporary SQLite database, runs `doctor`, exports a canonical snapshot, lists hosts, and produces an Ansible-compatible inventory artifact.
- `github-actions/inventory-review.yml` is a copy/paste GitHub Actions workflow example. It is intentionally stored under `examples/` rather than `.github/workflows/` so projects can adapt it before enabling it.

The example writes artifacts to `tmp/inventory-ci-artifacts` by default:

- `doctor.txt`
- `inventory.yml`
- `hosts.json`
- `ansible-inventory.json`

Use this pattern for pull-request review gates before applying inventory changes to a shared or production Moose Inventory database.
