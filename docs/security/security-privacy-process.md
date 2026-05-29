# Moose Inventory Security and Privacy Process

## Approval status

Status: **Approved**

Russ / Rusty Frink Desiato approved this document as the Moose Inventory security and privacy process baseline on 2026-05-29. Approval reference: `GOV-SEC-001`.

This document captures the maintained security and privacy process baseline for Moose Inventory. It is prepared from the approved product, requirements, CLI UX, and architecture baselines, plus current security-audit evidence and verification scripts.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.
- `GOV-UX-001`: `docs/ux/cli-workflow-notes.md` is approved as the CLI UX/workflow baseline.
- `GOV-ARCH-001`: `docs/architecture/architecture-and-trust-boundaries.md` is approved as the architecture and trust-boundary baseline.
- `GOV-SEC-001`: this document is approved as the security and privacy process baseline.

Scope limit: this document covers security and privacy process expectations for a Ruby CLI/RubyGem package. It is not release approval, accepted-risk approval, public/compliance-claim approval, RubyGems publishing approval, or approval to operate Moose Inventory as a hosted service. Approval of this baseline does not approve any proposed or monitored risk in the accepted-risk register.

## Security posture summary

Moose Inventory is a local/automation-run CLI and RubyGem. It is not a hosted service and does not provide authentication, multi-user authorization, network listeners, or a managed SaaS control plane.

The main security responsibilities are:

- avoid leaking inventory, environment, and credential data;
- avoid unsafe mutation of inventory state;
- preserve package and release integrity;
- keep dependencies and CI/release tooling scanned;
- give maintainers a clear vulnerability intake and patch process;
- record accepted risks explicitly instead of smuggling them through vibes, the least trustworthy transport layer.

## Assets and data classification

| Asset / data | Classification | Location / flow | Handling expectation |
| --- | --- | --- | --- |
| Inventory host and group names | Internal / environment-sensitive | User database, CLI output, snapshot exports, Ansible integration | Treat as potentially sensitive infrastructure metadata. Avoid publishing real inventories in examples, issues, logs, or screenshots. |
| Host/group variables | Internal to confidential depending on user content | User database, CLI output, snapshot exports, Ansible integration | Values may contain endpoints, usernames, tokens, or operational details. Users should not store secrets as inventory variables unless their environment explicitly protects them. |
| Database configuration | Confidential when credentials are present | YAML config files and selected environment sections | Prefer `password_env`; discourage committed plaintext passwords. Doctor should flag plaintext DB password configuration. |
| Environment variables containing DB passwords | Secret | User shell, CI environment, process environment | Do not log. Do not print in diagnostics. Rotate outside Moose Inventory if exposed. |
| SQLite database file | Internal to confidential | User-selected local filesystem path | User controls filesystem permissions, backups, and deletion. Backup copies inherit sensitivity of source data. |
| MySQL/MariaDB/PostgreSQL database state | Internal to confidential | User-managed database server | User controls database users, network access, server backup, restore, and encryption posture. |
| Audit/change records | Internal / environment-sensitive | User database audit tables and CLI audit output | Preserve append-only intent. Treat as operational history; avoid leaking in public bug reports. |
| Snapshot import/export files | Internal to confidential | Files passed to `import`/`export`, CI artifacts | Treat as inventory data. Review before sharing. Avoid storing secrets in exported snapshots. |
| CI/release artifacts and built gem | Public once released | GitHub Actions, RubyGems, local `tmp/pkg` | Verify package sanity and release workflow integrity before publishing. |
| Security-audit and release evidence | Internal to public depending on repo visibility | `docs/`, CI logs, release records | Avoid secrets. Make limitations explicit. Evidence is not approval by itself. |

## Data flows

### Local CLI mutation flow

```text
Human / automation caller
        |
        v
moose-inventory CLI arguments/options
        |
        v
config discovery + selected environment
        |
        v
operation object validation
        |
        v
transactional database write
        |
        v
CLI output + audit/change record where applicable
```

Security expectations:

- Validate arguments before mutation where practical.
- Keep dry-run non-mutating.
- Use transactions for write operations where practical.
- Do not print configured database passwords or environment-variable values.
- Keep destructive or high-risk changes explicit and reviewable.

### Snapshot import/export flow

```text
inventory.yml / inventory.json
        |
        v
parser + snapshot validator
        |
        v
transactional import apply OR validation failure
        |
        v
exported snapshot / CLI report / audit evidence
```

Security expectations:

- Validate before write.
- Treat snapshot files as potentially confidential.
- Do not make import a destructive sync unless separately designed, documented, tested, and approved.
- Future preview/diff behavior should remain non-mutating.

### Release and dependency flow

```text
source + Gemfile.lock + workflows
        |
        v
scripts/check.sh
        |
        +--> RSpec / coverage
        +--> RuboCop
        +--> git diff --check
        +--> permissions check
        +--> OSV / bundler-audit
        +--> gitleaks
        +--> package sanity
        |
        v
reviewed tag + GitHub release workflow
        |
        v
RubyGems trusted publishing / OIDC
```

Security expectations:

- Release jobs must require the same security-tool coverage expected by CI.
- A passing check is evidence, not release approval.
- Trusted publishing is the current package provenance baseline.
- Additional signed provenance or artifact attestations are future hardening, not a current blocker unless separately approved.

## Threat and abuse-case model

| ID | Threat / abuse case | Impact | Current controls | Follow-up posture |
| --- | --- | --- | --- | --- |
| T-001 | User commits plaintext DB passwords in config | Credential disclosure | README guidance, `password_env`, doctor finding for plaintext password config, local `gitleaks` gate | Keep plaintext password support for compatibility; prefer `password_env`; track secret-scanning limits in risk register. |
| T-002 | Inventory snapshots or audit output are shared publicly | Infrastructure metadata disclosure | Documentation guidance, export is explicit, audit output is user-invoked | Treat snapshots/audit as sensitive; future docs should repeat sharing guidance near examples. |
| T-003 | Wrong config/environment is selected | Accidental mutation of wrong inventory DB | Explicit `--config`, `--env`, config validation, dry-run support | Future destructive confirmation should show environment/config context. |
| T-004 | Destructive commands remove intended inventory state without enough friction | Operational disruption | Explicit command names, dry-run coverage, backlog item for destructive confirmation | Implement confirmation/`--yes` behavior before expanding destructive workflows. |
| T-005 | Malformed import file causes partial or inconsistent writes | Data corruption | Snapshot validation before apply, transactional import | Keep import validation coverage with schema changes. |
| T-006 | Duplicate/conflicting DB records bypass application logic | Corrupt inventory behavior | Schema uniqueness/index migrations, duplicate cleanup/refusal | Keep migration tests and future-schema refusal. |
| T-007 | CLI input reaches shell execution | Command injection | Application uses Ruby/Sequel operations, not shell execution for inventory mutations | Security reviews should re-check new integrations for shell invocation. |
| T-008 | Dependency vulnerability ships in a release | User environment compromise | OSV query, `osv-scanner`, `bundler-audit`, release parity enforcement | Patch according to vulnerability policy below; accept residual risk only through risk register. |
| T-009 | Secret scanner is unavailable in GitHub repository settings | Missed committed secrets | Local/CI `gitleaks` gate | Track as accepted/monitored residual risk until GitHub secret scanning is available/enabled. |
| T-010 | Release workflow publishes unreviewed or tampered package | Supply-chain compromise | GitHub Actions release workflow, trusted publishing/OIDC, package sanity, tag/version checks | Document confirmed release environment protections after maintainers verify settings. |
| T-011 | Database server backups/restores are assumed to be handled by Moose Inventory | Data loss or false assurance | Architecture says server-backed DB operations remain user-managed | Expand MySQL/MariaDB/PostgreSQL backup/restore guidance. |
| T-012 | AI-assisted maintenance performs external or irreversible actions without approval | Governance/security failure | Workspace process and approval register | Repo-local AI-agent boundaries remain a separate process item. |

## Authentication and authorization model

Moose Inventory does not authenticate users itself. It relies on the caller's local operating-system account, shell environment, filesystem permissions, and configured database credentials.

Authorization boundaries:

- CLI execution authority is inherited from the local user or automation account running the command.
- SQLite access is controlled by filesystem permissions.
- MySQL/MariaDB/PostgreSQL access is controlled by the configured database account and server policy.
- GitHub/RubyGems release authority is controlled outside the gem by repository, workflow, environment, and trusted-publishing configuration.

Security expectations:

- Use least-privilege database accounts where practical.
- Avoid sharing config files that contain credentials.
- Keep release and package-publishing authority human-owned and separately approved.
- Do not imply Moose Inventory provides RBAC or tenant isolation.

## Secrets handling model

Preferred posture:

- Use `password_env` for DB passwords.
- Store secrets in the caller's environment, shell secret manager, CI secret store, or database/platform secret mechanism.
- Keep plaintext `password` only as a compatibility option.

Rules:

- Do not print DB passwords in normal output, errors, doctor reports, or audit records.
- Do not add examples that contain real secrets, tokens, host inventories, or live infrastructure details.
- Do not commit `.env`, real config files, live inventory exports, database files, or secret-containing logs.
- If a secret is committed, rotate it outside Moose Inventory and record the incident/cleanup evidence.

## Logging and audit expectations

Moose Inventory has an append-only audit/change-history feature for inventory mutations. That audit log is product evidence and operational history, not a rollback system and not a tamper-proof security ledger.

Expectations:

- Mutating commands should record meaningful audit/change evidence where supported.
- Dry-runs should not mutate inventory state or audit history.
- Audit output may contain host/group names and variable names; treat it as environment-sensitive.
- Audit records should not include database passwords or environment-variable secret values.
- Any future richer audit export should document confidentiality and retention expectations.

## Privacy posture

Moose Inventory does not intentionally collect personal data, telemetry, analytics, or hosted-service user behavior.

Privacy expectations:

- No built-in telemetry without separate product approval.
- No external network calls during normal inventory operations except database connections explicitly configured by the user.
- Dependency/security checks in maintainer workflows may contact external advisory services such as OSV and Ruby advisory sources; this is release/maintenance evidence, not runtime telemetry.
- User inventories may include personal data if users put it there. Treat exported snapshots, audit records, and DB backups according to the sensitivity of user-provided content.

## Vulnerability intake and security patch policy

### Intake channels

Current maintained intake channels:

- GitHub issues for non-sensitive bugs and security-hardening requests.
- Direct maintainer contact or private coordination for sensitive vulnerability details when available.
- Security audit findings recorded under `docs/security-audit-*.md`.

Future improvement:

- Add a `SECURITY.md` file if maintainers want a public vulnerability-reporting policy on GitHub.

### Triage severity

Use the highest applicable severity:

- Critical: credible package compromise, credential disclosure in release tooling, arbitrary code execution reachable through normal CLI use, or destructive data corruption with no workaround.
- High: dependency vulnerability reachable in supported use, unsafe secret exposure, release workflow bypass, or destructive mutation bug likely to affect real inventory.
- Medium: validation bypass, denial-of-service condition, confusing security-sensitive UX, or hardening gap with plausible user impact.
- Low: documentation clarity, defense-in-depth, non-reachable dependency advisory, or scanner/process improvement.

### Patch targets

Targets are guidance, not an SLA promise:

- Critical: stop release activity, prepare fix or mitigation immediately, and require human approval before publishing.
- High: prioritize before feature work and target the next patch release.
- Medium: add to backlog with owner/evidence and fix in an upcoming maintenance slice.
- Low: handle opportunistically or with related docs/process work.

### Release and disclosure

- Do not publish a release that knowingly ships an unresolved critical/high security issue unless a human approver records accepted risk.
- Release notes should describe security fixes at an appropriate level without handing attackers a nicely gift-wrapped exploit manual.
- If a published gem is compromised or materially unsafe, a human maintainer must decide whether to yank, deprecate, patch, or publish an advisory.

## Security acceptance criteria

Security-ready for a release candidate means:

- `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh` passes or exceptions are explicitly recorded.
- No known unresolved critical/high findings remain unless accepted through the risk register.
- Dependency/advisory scans are current enough for the release decision.
- Secret scan passes or any finding is triaged, cleaned, and rotated where needed.
- Package sanity passes for the gem artifact.
- Release docs and checklist identify any accepted risks, limitations, and non-goals.
- Approval records distinguish evidence from human approval.

## Accepted-risk register relationship

Accepted risks live in `docs/security/accepted-risk-register.md`.

Rules:

- A risk entry may be proposed by an agent or maintainer, but acceptance requires explicit human approval.
- Each accepted risk must include scope, reason, compensating controls, owner, review trigger/date, and approval reference.
- Empty or pending risk tables are useful evidence; they do not mean all risk is approved.

## Current known limitations and compensating controls

| Limitation | Current posture | Compensating control / next action |
| --- | --- | --- |
| GitHub secret scanning is unavailable/disabled for this repository in current evidence | Not accepted as a permanent claim; tracked as residual posture | Local/CI `gitleaks` gate remains required. Revisit if GitHub secret scanning becomes available. |
| MySQL/MariaDB/PostgreSQL backups/restores are user-managed | Architecture scope boundary | Add expanded backup/restore guidance under architecture follow-up backlog. |
| Public vulnerability intake is informal | Draft process only | Consider adding `SECURITY.md` or GitHub private vulnerability reporting if maintainers want public intake clarity. |
| Destructive CLI confirmation is not fully implemented | UX follow-up backlog | Implement explicit confirmation / `--yes` behavior before expanding destructive workflows. |
| Additional package provenance is not required beyond trusted publishing | Architecture decision | Evaluate signed provenance/artifact attestations as future hardening if justified. |

## Review cadence

Review this document when any of the following changes:

- supported database adapters or schema migration behavior;
- import/export or audit data handling;
- release workflow, trusted publishing, or security scanning tools;
- vulnerability intake expectations;
- public security/compliance claims;
- a security incident, secret exposure, or accepted-risk decision.

At minimum, revisit before each material public release.