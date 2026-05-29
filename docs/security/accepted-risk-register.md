# Moose Inventory Accepted-Risk Register

## Approval status

Status: **Approved register - no accepted risks currently approved here**

Russ / Rusty Frink Desiato approved this register's structure and use as part of the Moose Inventory security/privacy process baseline on 2026-05-29. Approval reference: `GOV-SEC-001`.

Russ / Rusty Frink Desiato separately approved this accepted-risk register as the maintained accepted-risk register baseline for Moose Inventory on 2026-05-29. Approval reference: `GOV-RISK-REG-001`.

This register records security, privacy, release, and supply-chain risks that are intentionally accepted rather than fixed before a defined milestone. A proposed risk is not accepted until an approver records an explicit approval decision.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.
- `GOV-UX-001`: `docs/ux/cli-workflow-notes.md` is approved as the CLI UX/workflow baseline.
- `GOV-ARCH-001`: `docs/architecture/architecture-and-trust-boundaries.md` is approved as the architecture and trust-boundary baseline.
- `GOV-SEC-001`: this register's structure and use are approved as part of the security/privacy process baseline.
- `GOV-RISK-REG-001`: this register is approved as the maintained accepted-risk register baseline.

Scope limit: this register records accepted-risk decisions only. It does not approve a release, compliance claim, public advisory, RubyGems publishing, future architecture/security changes, or acceptance of any proposed/monitored risk listed below. Approval of the register baseline does not convert proposed or monitored risks into accepted risks.

## Acceptance rules

Each accepted risk must include:

- risk ID;
- decision and scope;
- severity;
- affected assets/workflows;
- rationale for acceptance;
- compensating controls;
- owner;
- review date or trigger;
- approver and approval date;
- related issue/commit/document evidence where applicable.

Evidence is not approval. A finding listed under proposed or monitored risks remains unaccepted until explicitly approved.

## Accepted risks

_No accepted risks are currently recorded._

## Proposed or monitored risks

| ID | Status | Severity | Risk | Current controls | Required decision / next action |
| --- | --- | --- | --- | --- | --- |
| RISK-SEC-001 | Monitored, not accepted as permanent | Medium | GitHub secret scanning is unavailable/disabled in current repository evidence, so GitHub-native secret scanning cannot be relied on as a control. | Local/CI `gitleaks` gate, `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh`, docs warning against committing secrets. | Revisit if GitHub secret scanning becomes available. If releases rely on this limitation long-term, record an explicit accepted-risk decision or enable equivalent control. |
| RISK-SEC-002 | Monitored, not accepted as release blocker | Low | Additional signed provenance/artifact attestations beyond RubyGems trusted publishing are not a current requirement. | RubyGems trusted publishing/OIDC, package sanity check, release workflow gate. | Evaluate as architecture follow-up if security-sensitive consumers or release policy justify the complexity. |
| RISK-SEC-003 | Open process gap, not accepted | Medium | Public vulnerability intake is informal without a repo-local `SECURITY.md` or private advisory workflow documented for users. | GitHub issues for non-sensitive reports, maintainer/private coordination where available, security audit docs. | Decide whether to add public `SECURITY.md` as part of security/privacy baseline approval or maintenance runbook work. |
| RISK-SEC-004 | Open UX gap, not accepted | Medium | Destructive CLI commands do not yet have a consistent explicit confirmation / `--yes` pattern. | Explicit command names, dry-run support, tests, UX implementation backlog. | Complete UX implementation backlog item before expanding destructive behavior. |

## Accepted-risk template

```markdown
### RISK-SEC-XXX: Short risk name

- Status: Proposed | Accepted | Retired
- Severity: Critical | High | Medium | Low
- Affected assets/workflows:
- Decision scope:
- Risk statement:
- Rationale for acceptance:
- Compensating controls:
- Owner:
- Review trigger/date:
- Approver:
- Approval date:
- Evidence:
```

## Review cadence

Review this register:

- before each material public release;
- when `scripts/check.sh` or security tooling changes;
- when a security audit finds a new issue;
- when a dependency advisory affects the supported dependency set;
- when release infrastructure, RubyGems trusted publishing, or GitHub environment protection changes;
- when a proposed risk is accepted, retired, or no longer accurate.
