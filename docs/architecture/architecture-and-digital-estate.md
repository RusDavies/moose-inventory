# Moose Inventory Architecture, Trust Boundary, and Digital Estate Baseline

## Approval status

Status: **Draft - not approved**

This document captures the current architecture, trust boundaries, data flows, and digital estate for Moose Inventory. It is prepared from the approved product brief, requirements baseline, CLI UX/workflow baseline, README, release docs, GitHub workflows, gemspec, and current source layout.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.
- `GOV-UX-001`: `docs/ux/cli-workflow-notes.md` is approved as the CLI UX/workflow baseline.

Pending approval: Russ or a delegated product owner must approve, revise, or reject this architecture and digital-estate baseline before it becomes approved architecture evidence.

Scope limit: this document covers architecture, trust boundaries, and digital estate only. It is not security/privacy design approval, release approval, accepted-risk approval, public/compliance-claim approval, or RubyGems publishing approval.

## System summary

Moose Inventory is a RubyGem and command-line application for managing Ansible-compatible dynamic inventory state in a database. It is packaged as the `moose-inventory` gem and exposes the `moose-inventory` executable.

The system is not a hosted service. Users operate it locally or in their own automation environments. Moose Inventory reads configuration, connects to a configured database, performs CLI-requested read/write operations, and emits human-readable or machine-readable output.

## High-level architecture

```text
Human / CI / Ansible workflow
        |
        v
bin/moose-inventory
        |
        v
Moose::Inventory::Cli::Application (Thor command tree)
        |
        +--> CLI command modules
        |       host, group, db, audit, console, import/export, doctor
        |
        +--> CLI support modules
        |       formatting, dry-run plan rendering, audit recording,
        |       relation rendering, variable rendering, tag support
        |
        v
Operation objects
        add/remove hosts, groups, associations, variables,
        child relations, snapshot import/export, inventory doctor,
        query inventory
        |
        v
InventoryContext / DB singleton / Sequel models
        |
        v
SQLite / MySQL-MariaDB / PostgreSQL database
```

External integration paths:

```text
Ansible inventory plugin example --> moose-inventory CLI / exported data
CI examples ---------------------> snapshot validation / inventory review
GitHub Actions CI ---------------> scripts/check.sh gate
GitHub Actions release ----------> RubyGems trusted publishing / OIDC
RubyGems users ------------------> installed gem and executable
```

## Main components

### Executable entrypoint

- `bin/moose-inventory`
- Loads the Ruby application and exposes the CLI.
- Treated as a packaged executable and package-sanity artifact.

### CLI layer

Key files:

- `lib/moose_inventory/cli/application.rb`
- `lib/moose_inventory/cli/host*.rb`
- `lib/moose_inventory/cli/group*.rb`
- `lib/moose_inventory/cli/db.rb`
- `lib/moose_inventory/cli/audit.rb`
- `lib/moose_inventory/cli/console.rb`
- `lib/moose_inventory/cli/formatter.rb`
- `lib/moose_inventory/cli/plan_rendering.rb`
- CLI support modules for tags, variables, relationships, listvars, and audit recording

Responsibilities:

- Parse commands and options.
- Select config/environment.
- Invoke operation objects.
- Render human-readable and machine-readable output.
- Preserve documented CLI behavior and output compatibility.
- Enforce UX constraints such as dry-run/plan option combinations.

### Configuration layer

Key file:

- `lib/moose_inventory/config/config.rb`

Responsibilities:

- Discover and parse YAML configuration.
- Resolve selected environment.
- Validate database adapter configuration.
- Prefer environment-variable based passwords through `password_env`.

### Operation layer

Key files:

- `lib/moose_inventory/operations/add_hosts.rb`
- `lib/moose_inventory/operations/remove_hosts.rb`
- `lib/moose_inventory/operations/add_groups.rb`
- `lib/moose_inventory/operations/remove_groups.rb`
- `lib/moose_inventory/operations/add_associations.rb`
- `lib/moose_inventory/operations/remove_associations.rb`
- `lib/moose_inventory/operations/group_child_relations.rb`
- `lib/moose_inventory/operations/add_variables.rb`
- `lib/moose_inventory/operations/remove_variables.rb`
- `lib/moose_inventory/operations/import_inventory_snapshot*.rb`
- `lib/moose_inventory/operations/inventory_snapshot.rb`
- `lib/moose_inventory/operations/inventory_doctor.rb`
- `lib/moose_inventory/operations/query_inventory*.rb`

Responsibilities:

- Implement inventory business behavior independently of CLI rendering where practical.
- Emit structured events for CLI progress, dry-run plans, and review.
- Validate before writing for snapshot import and safety-sensitive workflows.
- Use transactions through `InventoryContext` and DB helpers.

### Database and schema layer

Key files:

- `lib/moose_inventory/db/db.rb`
- `lib/moose_inventory/db/models.rb`
- `lib/moose_inventory/db/schema_migrations.rb`
- `lib/moose_inventory/inventory_context.rb`

Responsibilities:

- Establish Sequel database connections.
- Bind models to the active database.
- Create and migrate schema through explicit ordered migrations.
- Refuse newer schemas than the code supports.
- Provide transaction and model access seams to operations.

Supported adapters:

- SQLite
- MySQL/MariaDB
- PostgreSQL

### Release and verification layer

Key files:

- `scripts/check.sh`
- `scripts/ci/*.sh`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `moose-inventory.gemspec`
- `docs/release/publishing.md`
- `docs/release/release-readiness.md`

Responsibilities:

- Run tests, lint, whitespace checks, permissions checks, dependency security checks, secret scanning, and package sanity checks.
- Verify release tag/version alignment.
- Publish to RubyGems through trusted publishing/OIDC when a reviewed release tag is pushed.

## Runtime data model

Conceptual inventory entities:

- hosts
- groups
- host variables
- group variables
- host-group associations
- parent/child group associations
- host metadata tags
- group metadata tags
- schema version records
- audit/change records

Key invariants:

- Host/group names are normalized where existing behavior requires it.
- Join/variable uniqueness is enforced by schema constraints where implemented.
- Group cycles should be rejected or reported.
- Automatic `ungrouped` behavior is preserved for host/group association cleanup.
- Import is additive/update-oriented, not destructive sync.

## Trust boundaries

### Boundary 1: Human or automation caller to CLI

Inputs:

- command names/options/arguments
- config path and environment selection
- snapshot import files
- shell environment variables

Risks:

- accidental destructive command
- malformed arguments
- secret exposure through shell history or output
- wrong config/environment selected

Controls:

- command family structure and help text
- dry-run and plan output
- early validation before mutation
- transactions
- future destructive-command confirmation backlog item

### Boundary 2: CLI to configuration file/environment

Inputs:

- YAML config files
- `password_env` variables
- legacy plaintext `password`

Risks:

- committed credentials
- wrong database target
- missing or malformed config

Controls:

- README recommends `password_env`
- doctor flags plaintext passwords
- config validation fails before command execution where practical
- generated/runtime config should stay outside commits

### Boundary 3: Application to database

Inputs/outputs:

- SQL operations through Sequel
- schema migration records
- inventory data
- audit records

Risks:

- partial writes
- schema drift
- duplicate/corrupt relationships
- writes by older code against newer DB schema

Controls:

- transactions for mutating commands where practical
- explicit ordered migrations
- future-schema refusal
- uniqueness/index constraints
- import validation before writes
- doctor checks for known consistency issues

### Boundary 4: Snapshot files to application

Inputs:

- YAML/JSON inventory snapshots

Risks:

- malformed data
- unexpected references
- duplicate normalized keys
- whitespace-only names
- cycles in group hierarchy
- user misunderstanding additive import semantics

Controls:

- snapshot validation before DB writes
- additive import only
- no destructive restore/sync semantics without future approval
- future preview/diff backlog item

### Boundary 5: Application output to humans/scripts

Outputs:

- human-readable CLI progress
- YAML/JSON/pjson output
- doctor findings
- dry-run plan events
- audit list output

Risks:

- breaking automation by changing formats
- misleading human output
- leaking sensitive inventory structure or credentials

Controls:

- approved UX baseline
- output compatibility backlog item
- tests for important output contracts
- avoid secret output in errors/examples

### Boundary 6: Repository to CI/release infrastructure

Inputs/outputs:

- pushes and pull requests to GitHub
- `v*` release tags
- GitHub Actions jobs
- RubyGems trusted publishing OIDC token
- built gem artifact

Risks:

- publishing wrong version
- unreviewed release
- CI bypass
- compromised dependency/release tooling
- RubyGems full-index lag causing false negatives

Controls:

- CI matrix for Ruby 3.2, 3.3, and 3.4
- release workflow checks tag version against gem version
- full check gate before publishing
- trusted publishing, no RubyGems API key in GitHub secrets
- `await-release: false` plus direct post-release verification guidance
- human release approval remains required

## Data flows

### Read-only inspection flow

```text
User/automation -> CLI args/options -> config/env -> DB query -> formatter -> terminal/JSON/YAML
```

Properties:

- no inventory mutation intended
- should not create audit mutation records
- machine-readable formats must remain parseable

### Mutating command flow

```text
User -> CLI command -> validation -> transaction -> operation -> Sequel models -> DB
                         |                              |
                         v                              v
                   progress events                audit record where applicable
```

Properties:

- writes are transactional where practical
- output reflects planned or applied changes
- dry-run follows the planned path without DB mutation

### Snapshot import flow

```text
Snapshot file -> parser -> validator -> transaction -> applier -> DB -> summary output
```

Properties:

- validation occurs before write
- failed validation leaves DB unchanged
- import is additive/update-oriented

### Release flow

```text
maintainer decision -> version/tag -> GitHub release workflow -> check gate -> RubyGems OIDC -> published gem
```

Properties:

- release tag must match `Moose::Inventory::VERSION`
- full local check gate runs in release workflow
- publishing uses RubyGems trusted publishing
- release approval is a human-owned decision

## Digital estate register

| Asset | Location / identifier | Owner / steward | Purpose | Current controls | Notes |
| --- | --- | --- | --- | --- | --- |
| Source repository | `https://github.com/RusDavies/moose-inventory` | Russ / repository maintainers | Source, issues, CI, releases | GitHub auth, branch history, CI workflow | Current local `master` may be ahead of origin during active work. |
| RubyGem | `moose-inventory` on RubyGems.org | RubyGems gem owners | Public package distribution | RubyGems MFA metadata, trusted publishing | Publishing requires explicit human release approval. |
| GitHub Actions CI | `.github/workflows/ci.yml` | Repository maintainers | Test matrix and check gate | Read-only contents permission, Ruby matrix, security tools | Runs on master pushes, pull requests, and manual dispatch. |
| GitHub Actions release | `.github/workflows/release.yml` | Repository maintainers | Trusted publishing to RubyGems | `contents: write`, `id-token: write`, release environment, tag/version check | Runs on `v*` tags. |
| GitHub environment | `release` | Repository maintainers | OIDC trusted publishing environment | Environment protection if configured | Required by RubyGems trusted publisher. |
| RubyGems trusted publisher | Owner `RusDavies`, repo `moose-inventory`, workflow `release.yml`, environment `release` | RubyGems gem owners | Short-lived publishing token | OIDC trusted publishing | No RubyGems API key should be stored in GitHub secrets for normal releases. |
| Local developer workstations | Maintainer machines | Individual maintainers | Development, manual fallback release if approved | Local git, Bundler, RubyGems credentials if fallback used | Manual publishing is fallback only and should use scoped credentials. |
| Local/CI test artifacts | `spec/reports/coverage`, `tmp/pkg`, `tmp/package-sanity` | Maintainers/CI | Verification output | Ignored/generated cleanup expectations | Do not commit generated runtime artifacts unless intentional. |
| User inventory databases | User-managed SQLite/MySQL/PostgreSQL | End users/operators | Inventory state | User DB permissions/backups | Outside project operation; docs should treat as sensitive. |
| User config files | User-managed YAML config | End users/operators | DB/environment config | `password_env` recommendation | Plaintext passwords are compatibility only, not preferred. |
| Exported snapshots | User-selected paths | End users/operators | Backup/review/migration | User file permissions | Potentially sensitive operational data. |
| Audit records | User DB | End users/operators | Change evidence | Append-only application behavior | Evidence only, not rollback mechanism. |

## Maintainer ownership boundaries

Human-owned decisions:

- product direction beyond approved baselines
- architecture baseline approval
- security/privacy design approval
- accepted risk
- public/security/compliance claims
- release approval
- RubyGems publishing
- destructive repository/package actions

Agent/automation-appropriate work:

- draft docs and process evidence
- update backlog items
- implement local code/doc/test changes on branches
- run local verification gates
- prepare release evidence and checklists
- identify gaps and propose remediation

Automation must not infer approval from passing tests, drafted docs, or existing process artifacts.

## Architecture decision notes

Current notable architecture decisions:

1. Keep Moose Inventory as a Ruby CLI/RubyGem rather than a hosted service.
2. Keep Ansible plugin material as examples rather than adding a Python/Ansible runtime dependency to the gem.
3. Keep snapshot import additive/update-oriented; destructive restore/sync requires separate design and approval.
4. Keep audit history as evidence only, not rollback/change-set UX.
5. Use explicit ordered schema migrations and refuse future schemas.
6. Use RubyGems trusted publishing/OIDC as the preferred publishing path.
7. Preserve CLI output compatibility unless breaking changes are explicitly approved.

## Open architecture and estate questions

1. Should architecture baseline approval require a lightweight text diagram review only, or should future major architecture changes add richer diagrams?
2. Should the digital estate register track specific GitHub/RubyGems human account names, or keep ownership role-based to avoid stale personal-data records?
3. Should release environment protection rules be documented in more detail after maintainers confirm the current GitHub environment settings?
4. Should package provenance beyond RubyGems trusted publishing, such as signed provenance artifacts, become an architectural requirement?
5. Should user database backup/restore guidance be expanded beyond SQLite backup behavior for MySQL/MariaDB and PostgreSQL?
