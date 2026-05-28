# Moose Inventory Requirements and Acceptance Criteria Baseline

## Approval status

Status: **Draft — not approved**

This baseline is prepared from the approved product brief, current README, test/release/security evidence, and existing CLI behavior. It is not approved requirements, release approval, accepted-risk approval, public/compliance-claim approval, or RubyGems publishing approval.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.

Pending approval: Russ or a delegated product owner must approve, revise, or reject this requirements baseline before it becomes the durable requirements baseline.

## Change-control note

Until this document is approved, the README, specs, and current CLI behavior remain the practical behavior baseline. After approval:

- New features should map to one or more requirements or add/update a requirement.
- Breaking CLI/API/schema behavior changes require explicit approval and migration notes.
- Release candidates should produce evidence that the applicable acceptance criteria pass or that exceptions are explicitly accepted as risk.
- Documents, tests, scans, and checklists are evidence, not approval.

## Requirement categories

Requirement IDs use these prefixes:

- `CLI`: command-line behavior
- `CFG`: configuration and environment selection
- `DB`: database lifecycle, adapters, and schema
- `INV`: inventory model and mutation behavior
- `DRY`: dry-run and plan output
- `SNAP`: import/export snapshots
- `DOC`: inventory doctor/lint behavior
- `AUD`: audit/change history
- `TAG`: metadata tags
- `ANS`: Ansible integration
- `CI`: CI/CD integration examples
- `PKG`: package/release integrity
- `SEC`: security/privacy expectations
- `COMPAT`: compatibility and support boundaries
- `DOCS`: user/maintainer documentation

## Functional requirements

### CLI behavior

#### CLI-001: Help and discoverability

The CLI must expose help at the top level and command-family level.

Acceptance criteria:

- `moose-inventory help` displays top-level help.
- `moose-inventory help group` displays group help.
- `moose-inventory group help add` displays command-specific help.
- Help examples in README remain representative of supported command families.

#### CLI-002: Output formats

Read/list/get/report commands that document `--format` must support `yaml`, `json`, and `pjson` where applicable.

Acceptance criteria:

- Supported formats are documented in README.
- Unsupported formats fail predictably without mutating inventory.
- Machine-readable output remains parseable by the declared format.

#### CLI-003: Existing behavior preservation

Existing documented command behavior and tested output should remain compatible unless a breaking change is explicitly approved.

Acceptance criteria:

- Regression tests cover legacy behavior that is intentionally preserved.
- Breaking changes include an approval record and migration/release note.
- Default human-readable output is not changed accidentally during refactors.

### Configuration and environment selection

#### CFG-001: Config discovery

The CLI must search documented config locations in precedence order and allow an explicit `--config <FILE>` override.

Acceptance criteria:

- Explicit `--config` takes precedence and must reference an existing file.
- Default search paths remain documented.
- Missing/invalid config errors are clear and non-mutating.

#### CFG-002: Environment selection

The CLI must use `general.defaultenv` by default and allow `--env <SECTION>` to select another environment.

Acceptance criteria:

- Missing environment sections fail clearly.
- Environment sections remain isolated by database configuration.
- Commands use the selected environment consistently.

#### CFG-003: Database credential handling

Database configuration must support `password_env` for MySQL/MariaDB and PostgreSQL and retain legacy plaintext `password` compatibility.

Acceptance criteria:

- README recommends `password_env` over plaintext `password`.
- Doctor/security checks flag plaintext database password configuration.
- Plaintext password support is treated as compatibility, not preferred posture.

### Database lifecycle, adapters, and schema

#### DB-001: Supported adapters

Moose Inventory must support SQLite, MySQL/MariaDB, and PostgreSQL adapters as documented.

Acceptance criteria:

- SQLite is exercised by the automated test suite.
- MySQL/MariaDB and PostgreSQL adapter dispatch/error paths have smoke coverage without requiring live servers.
- Adapter-specific configuration requirements are documented.

#### DB-002: Transactional mutations

Mutating commands must perform database changes transactionally where practical.

Acceptance criteria:

- A command either applies its intended database changes or rolls them back on failure.
- Import validation completes before import writes begin.
- Dry-run commands do not mutate database state.

#### DB-003: Explicit schema versioning and migration

Database schema changes must use explicit ordered migrations.

Acceptance criteria:

- Schema version metadata is maintained.
- Known migrations run in order.
- Older code refuses to write to a database with a newer schema version.
- `db status`, `db doctor`, and `db migrate` report/handle schema state as documented.

#### DB-004: Backup support

The CLI must provide documented database backup behavior for SQLite and clear boundaries for server-backed databases.

Acceptance criteria:

- SQLite backup command copies the configured database to the requested destination.
- MySQL/MariaDB and PostgreSQL backup limitations are documented or reported clearly.
- Backup commands avoid destructive behavior.

### Inventory model and mutation behavior

#### INV-001: Host and group management

The CLI must support creating, listing, inspecting, and removing hosts and groups.

Acceptance criteria:

- Host/group create operations are idempotent or report existing state as currently documented/tested.
- Removal operations clean up related associations according to documented behavior.
- Group recursive removal behavior is explicit and tested.

#### INV-002: Host-group relationships

The CLI must support adding/removing hosts to/from groups through host-oriented and group-oriented command families.

Acceptance criteria:

- `host addgroup`, `host rmgroup`, `group addhost`, and `group rmhost` preserve existing output contracts.
- Automatic `ungrouped` behavior is preserved.
- Missing host/group behavior remains explicit and non-surprising.

#### INV-003: Child-group relationships

The CLI must support adding/removing child groups while preventing invalid group hierarchy states.

Acceptance criteria:

- Circular child-group relationships are rejected or reported by validation/doctor checks.
- `--delete-orphans` behavior remains explicit.
- Parent/child cleanup behavior is tested.

#### INV-004: Variables

The CLI must support host and group variable creation, update, listing, and removal.

Acceptance criteria:

- Variable names and values are validated according to current CLI/import rules.
- Variable mutation commands preserve transactional behavior.
- Variable list/get output remains machine-readable where documented.

#### INV-005: Host list filtering

Host listing must support documented filters using database-backed queries where implemented.

Acceptance criteria:

- Group, tag, and variable filters behave as AND predicates when multiple filters are provided.
- Missing filters return empty results rather than broadening results.
- Output shape and ordering remain compatible with documented/tested behavior.

### Dry-run and plan output

#### DRY-001: Dry-run support for mutating commands

Documented mutating command families must support `--dry-run`.

Acceptance criteria:

- Dry-run renders planned progress without database mutation.
- Dry-run ends with `Dry run complete. No changes applied.`
- Dry-run behavior covers host/group create/remove, variable mutations, host/group associations, and child-group relationship commands as documented.

#### DRY-002: Machine-readable plan output

Dry-run commands must support `--plan-format yaml|json|pjson` for automation/review workflows.

Acceptance criteria:

- `--plan-format` requires `--dry-run`.
- Without `--dry-run`, the command aborts before writes with the documented error.
- Plan events include ordered event type and payload details sufficient for scripts to inspect intended changes.

### Import/export snapshots

#### SNAP-001: Snapshot export

The CLI must export the full inventory as a portable snapshot.

Acceptance criteria:

- Snapshot includes version, hosts, groups, variables, tags, host/group memberships, and child-group relationships.
- YAML/JSON output is parseable.
- Export does not mutate inventory.

#### SNAP-002: Snapshot import validation

The CLI must validate snapshots before writing.

Acceptance criteria:

- Malformed snapshots, unknown references, unsupported fields, invalid variable shapes, duplicate normalized keys, whitespace-only names, and circular group hierarchies are rejected before writes.
- Failed import leaves the database unchanged.

#### SNAP-003: Additive import semantics

Snapshot import must remain additive/update-oriented unless destructive restore/sync semantics are separately approved.

Acceptance criteria:

- Import creates missing hosts/groups, adds missing associations/tags, and creates/updates variables found in the snapshot.
- Import does not delete existing inventory records absent from the file.
- Any future destructive import mode requires explicit requirements, UX, recovery, and approval records.

### Inventory doctor/lint behavior

#### DOC-001: Read-only health checks

The `doctor` command must run read-only health checks and exit non-zero when findings are present.

Acceptance criteria:

- Doctor finds documented inventory/config issues.
- Doctor supports human-readable output plus `yaml`, `json`, and `pjson` machine-readable formats.
- Doctor does not mutate inventory.

### Audit/change history

#### AUD-001: Append-only audit evidence

Successful mutating commands must record append-only audit evidence where audit support applies.

Acceptance criteria:

- Audit records include useful action, actor, target, metadata, and timestamp details.
- Dry-runs do not create mutation audit records.
- Audit listing supports documented formats and limits.

### Metadata tags

#### TAG-001: Host/group metadata tags

Hosts and groups must support metadata tags separate from Ansible variables.

Acceptance criteria:

- Tag add/list/remove commands work for hosts and groups.
- Tags are deduplicated per host/group.
- Tag normalization rules are documented and consistently applied after the relevant backlog item is completed.

### Ansible integration

#### ANS-001: Dynamic inventory compatibility

Moose Inventory must support Ansible-compatible dynamic inventory workflows.

Acceptance criteria:

- README documents how to use Moose Inventory with Ansible.
- Example inventory plugin/shim files remain packaged as examples.
- The RubyGem does not take an unnecessary Python/Ansible runtime dependency solely for examples.

#### ANS-002: Inventory mutation from Ansible

Documented Ansible write-back patterns must remain accurate where supported.

Acceptance criteria:

- README examples reflect supported command behavior.
- Security-sensitive write-back assumptions are documented or deferred to security guidance.

### CI/CD integration examples

#### CI-001: Inventory review examples

The repository should include CI/CD examples for validating and reviewing inventory snapshots.

Acceptance criteria:

- Example workflows/scripts are present under `examples/ci/`.
- Examples avoid embedding credentials or environment-specific secrets.
- Examples are covered by repository checks where practical.

## Non-functional requirements

### Package/release integrity

#### PKG-001: Release verification gate

Release candidates must pass the full project verification gate or record explicit accepted-risk exceptions.

Acceptance criteria:

- `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh` passes for release-candidate code unless an exception is explicitly accepted.
- Gate includes tests, coverage, RuboCop, whitespace/permission checks, dependency security checks, secret scanning, and package sanity.
- Release evidence records the exact command and result.

#### PKG-002: Trusted publishing

RubyGems publishing should use trusted publishing/OIDC where configured.

Acceptance criteria:

- Release workflow uses the documented trusted-publishing path.
- Publishing requires explicit human release approval.
- Release docs describe required RubyGems/GitHub setup and post-release verification.

#### PKG-003: Dependency and platform support

Runtime and development dependency ranges must remain intentional and reviewed.

Acceptance criteria:

- Gem dependency ranges are reviewed during release prep.
- Supported Ruby versions align with CI matrix and gemspec requirements.
- Dependency security checks pass or exceptions are accepted risk.

### Security/privacy expectations

#### SEC-001: Secret handling

Moose Inventory must avoid encouraging committed plaintext secrets.

Acceptance criteria:

- README recommends `password_env`.
- Doctor flags plaintext password config.
- Secret scanning is part of the verification gate.

#### SEC-002: Inventory data sensitivity

Docs and future security guidance must treat inventory data as potentially sensitive operational information.

Acceptance criteria:

- Exported snapshots, audit logs, and DB files are treated as sensitive artifacts.
- Examples avoid real credentials, hosts, or organization-specific secrets.
- Future docs do not imply inventory data is harmless.

#### SEC-003: Human-owned security decisions

Accepted risks, release security gates, public/security claims, and publishing decisions require human approval.

Acceptance criteria:

- Approval register or release evidence records human decisions.
- Passing scans are not represented as approval.
- Public/compliance claims are not made without explicit approval.

### Compatibility and support boundaries

#### COMPAT-001: Operating-system support boundary

UNIX/Linux remains the documented target unless Windows support is separately approved.

Acceptance criteria:

- README continues to warn that Windows is not currently a committed target.
- Windows support claims are not added without requirements, tests, and approval.

#### COMPAT-002: Machine-readable compatibility

Machine-readable formats should be treated as automation-facing interfaces.

Acceptance criteria:

- Changes to JSON/YAML/pjson structures are reviewed for compatibility impact.
- Breaking format changes require approval and migration notes.

#### COMPAT-003: Human-readable compatibility

Human-readable output should remain stable where tests or downstream examples rely on it.

Acceptance criteria:

- Refactors preserve existing wording/newline behavior where tests lock it.
- Intentional wording changes include test updates and release notes.

### Documentation

#### DOCS-001: README as user-facing source

Every new user-facing feature must be documented in README in the existing style.

Acceptance criteria:

- Feature branches update README for new commands/options/behavior.
- README examples are kept accurate enough for users to follow.
- Generated/runtime artifacts are not committed as documentation unless intentional.

#### DOCS-002: Process evidence docs

Process docs must distinguish draft evidence from approval.

Acceptance criteria:

- Approval status appears in product/process docs where relevant.
- Approval decisions are recorded in the approval register or equivalent durable evidence.
- Backlog status is updated when process artifacts are drafted or approved.

## Release acceptance summary

A release candidate is not requirements-conformant until:

1. Applicable functional requirements are implemented or explicitly deferred.
2. The full verification gate passes or exceptions are accepted as risk.
3. README and relevant docs reflect the release behavior.
4. Security-sensitive changes have validation, transaction, dry-run, audit, or recovery behavior as appropriate.
5. Release approval and accepted-risk disposition are recorded by a human approver.
6. RubyGems publishing, if any, is explicitly approved for that release.

## Open requirements questions

1. Should the project formally freeze compatibility expectations for human-readable output, or only for machine-readable formats?
2. Should snapshot import gain an explicitly destructive sync/restore mode, and what confirmation/recovery controls would be required?
3. Should audit history become a rollback/change-set system or remain accountability/debug evidence?
4. What exact Ruby/database support window should apply after each release?
5. Should package signing/provenance beyond RubyGems trusted publishing become a requirement?
6. Should tag normalization be fully case-insensitive across all import/export/CLI paths?
