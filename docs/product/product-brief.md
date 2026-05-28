# Moose Inventory Product Brief

## Approval status

Status: **Draft — not approved**

This brief is a product-framing baseline prepared from the current repository, README, release/security evidence, and approved process tailoring. It is not a product-direction approval, requirements approval, release approval, accepted-risk approval, or public/compliance claim.

Approved tailoring reference: `GOV-TAILOR-001` in `docs/governance/approval-register.md` approves Moose Inventory as **Class 4 with target profile Software Library / Package**.

Pending approval: Russ or a delegated product owner must approve, revise, or reject this product brief before it becomes the durable product baseline.

## Summary

Moose Inventory is a RubyGem and CLI for managing Ansible-compatible dynamic inventory state across local SQLite, MySQL/MariaDB, and PostgreSQL databases. It helps operators and automation workflows create, inspect, change, validate, import/export, and audit inventory data without hand-editing dynamic inventory structures.

The product is a software library/package and command-line tool, not a hosted service. It ships code, examples, CLI workflows, release artifacts, and documentation. It does not currently operate a production service on behalf of users.

## Target users

Primary users:

- Infrastructure engineers managing Ansible inventory data.
- DevOps/SRE practitioners who need repeatable CLI-based inventory changes.
- Automation maintainers who want machine-readable inventory export, validation, and dry-run plans.
- Ruby/Ansible users who prefer a packaged CLI and local database-backed inventory manager.

Secondary users:

- Security or release reviewers checking inventory changes before application.
- CI/CD maintainers integrating inventory review into pipelines.
- Future maintainers of the Moose Inventory RubyGem and release process.

## Core user problems

Moose Inventory is intended to solve these problems:

1. Keep dynamic Ansible inventory data in a structured database rather than scattered hand-maintained files.
2. Provide CLI operations for common host, group, variable, tag, and relationship changes.
3. Support reviewable dry-runs and machine-readable plans before mutating inventory state.
4. Export and import inventory snapshots for migration, review, backup, and automation workflows.
5. Validate inventory health before release, deployment, or operational change.
6. Preserve append-only audit evidence for successful mutating CLI commands.
7. Package and publish the tool through RubyGems with repeatable verification and trusted publishing.

## Primary use cases

### Manage inventory entities

Users can create, list, inspect, and remove hosts and groups. Host/group relationships and child-group relationships model Ansible-style inventory organization.

### Manage variables and metadata

Users can add/remove host and group variables and attach metadata tags that are separate from Ansible variables. Tags support operational labels such as environment, owner, lifecycle, location, role, and criticality.

### Review changes before applying them

Mutating commands support `--dry-run`. Dry-runs render planned progress without database mutation. For automation and review, `--plan-format yaml|json|pjson` emits structured planned events.

### Validate inventory health

The `doctor` command performs read-only inventory checks and returns non-zero when findings are present, supporting CI/release-gate workflows.

### Import/export inventory snapshots

Users can export portable inventory snapshots and import validated snapshots into another database. Import is additive/update-oriented and validates the snapshot before writing.

### Maintain database schema safely

Database lifecycle commands inspect, migrate, and back up supported databases. Schema migrations are explicit and ordered. The tool refuses to write to databases with a newer schema version than it supports.

### Support CI/CD and Ansible integration

The repository includes Ansible inventory plugin examples and CI integration examples without adding Ansible/Python runtime dependencies to the RubyGem itself.

## Product goals

1. Provide a reliable, scriptable CLI for database-backed Ansible dynamic inventory management.
2. Preserve existing command behavior and output compatibility unless a breaking change is deliberately approved.
3. Prefer safe change workflows: transactions, dry-run previews, validation before write, explicit migrations, and audit logging.
4. Support common local and server-backed database adapters: SQLite, MySQL/MariaDB, and PostgreSQL.
5. Keep the package lightweight and avoid unnecessary runtime dependencies.
6. Maintain strong release hygiene through tests, linting, dependency security checks, secret scanning, package sanity checks, and trusted publishing.
7. Keep documentation practical for CLI users, maintainers, reviewers, and automation consumers.

## Non-goals

The current product baseline does not include:

- Hosted service operation, web UI, SaaS control plane, or managed inventory hosting.
- General-purpose configuration-management replacement beyond inventory management.
- A full rollback system for audit events or imported snapshots.
- Silent destructive restore semantics.
- Windows support as a committed compatibility target.
- Compliance certification claims such as SOC 2, ISO 27001, ISO 42001, or similar readiness claims.
- Release approval, risk acceptance, public compliance claims, or RubyGems publishing without explicit human approval.

## Security-sensitive context

Moose Inventory can affect infrastructure operations because inventory data drives Ansible execution. A wrong host/group/variable relationship can point automation at the wrong machines or wrong environment.

Security-sensitive assets and flows include:

- Local or server-backed inventory databases.
- Configuration files that identify environments and database connections.
- Database credentials, especially legacy plaintext `password` values.
- Environment variables used for database passwords.
- Exported inventory snapshots.
- Audit logs that may reveal host/group names, actors, and operational structure.
- RubyGem release artifacts and GitHub Actions trusted-publishing configuration.

Current product posture:

- Prefer `password_env` over plaintext database passwords.
- Avoid committing database credentials and generated/runtime inventory files.
- Use transactions for mutating commands.
- Use validation before import writes.
- Exclude dry-run commands from audit mutation history because no mutation occurred.
- Treat release publishing, accepted risk, and public/security claims as human-owned decisions.

## Compatibility and stability expectations

Until explicitly changed by an approved requirements baseline:

- Existing documented CLI commands should remain compatible.
- Existing default human-readable output should be preserved where tests already lock behavior.
- Machine-readable formats should remain stable enough for automation consumers.
- Schema migrations should be additive and ordered where practical.
- Older code must refuse newer schemas rather than downgrade or corrupt them.
- Database-adapter behavior should remain conservative and explicit.

## Assumptions

- Users are comfortable with command-line workflows and Ansible inventory concepts.
- Users can install Ruby and native database client build dependencies when required.
- SQLite is suitable for local/small workflows; MySQL/MariaDB and PostgreSQL are available for server-backed inventory stores.
- Users manage their own database backups, especially for MySQL/MariaDB and PostgreSQL.
- Users are responsible for protecting their inventory data, database credentials, and generated artifacts.

## Success criteria

A release or major change is product-aligned when:

- CLI behavior remains compatible or the breaking change has explicit approval and migration guidance.
- The full verification gate passes for the release candidate.
- Security/dependency/secret/package checks pass or exceptions are explicitly recorded as accepted risk.
- README and relevant docs are updated in the existing style.
- Release evidence includes a human release decision, not just passing checks.
- New features include tests, documentation, and backlog closure evidence.
- Security-sensitive flows have dry-run, validation, transaction, or documented recovery behavior where appropriate.

## Open product questions

These remain unresolved until future approval or requirements work:

1. Should Moose Inventory formally support Windows, or continue documenting UNIX/Linux as the supported target?
2. What compatibility policy should apply to CLI human-readable output vs machine-readable output?
3. Should audit logs grow into rollback/change-set functionality, or remain accountability/debug evidence only?
4. Should snapshot import ever support destructive sync/restore semantics, and if so what confirmation/recovery controls are required?
5. What is the expected support policy for Ruby versions and database adapter versions after each release?
6. Should package signing or provenance beyond RubyGems trusted publishing be added?
