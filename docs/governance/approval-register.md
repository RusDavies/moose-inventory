# Moose Inventory Approval Register

This register records durable approvals and explicitly separates prepared evidence from human approval.

## Current status

The process tailoring baseline is approved as Class 4 with target profile Software Library / Package.

## Approved decisions

| ID | Decision | Approver | Date | Scope | Conditions / limitations |
| --- | --- | --- | --- | --- | --- |
| GOV-TAILOR-001 | Tailor Moose Inventory as Class 4, target profile Software Library / Package | Russ / Rusty Frink Desiato | 2026-05-28 | Process baseline for this repository | Approval covers project class and target profile only. It does not approve product brief, requirements, CLI UX, architecture, security/privacy design, release, accepted risk, public/compliance claims, or future RubyGems publishing. Pure software-library target excludes normal hosted-runtime operations unless Moose Inventory later adds an operated runtime component. |
| GOV-PRODUCT-001 | Approve `docs/product/product-brief.md` as the product-framing baseline | Russ / Rusty Frink Desiato | 2026-05-28 | Product framing for Moose Inventory | Approval covers the product brief as product-framing baseline only. It does not approve detailed requirements, CLI UX, architecture, security/privacy design, release, accepted risk, public/compliance claims, or future RubyGems publishing. Open product questions remain unresolved until separately decided. |
| GOV-REQ-001 | Approve `docs/product/requirements-baseline.md` as the requirements and acceptance criteria baseline | Russ / Rusty Frink Desiato | 2026-05-28 | Requirements and acceptance criteria for Moose Inventory | Approval covers the requirements and acceptance criteria baseline only. It does not approve CLI UX, architecture, security/privacy design, release, accepted risk, public/compliance claims, future RubyGems publishing, or answers to open requirements questions that require separate decisions. |
| GOV-UX-001 | Approve `docs/ux/cli-workflow-notes.md` as the CLI UX/workflow baseline | Russ / Rusty Frink Desiato | 2026-05-28 | CLI UX/workflow baseline for Moose Inventory | Approval covers command-line workflows and interaction conventions only. It does not approve architecture, security/privacy design, release, accepted risk, public/compliance claims, future RubyGems publishing, or implementation of the UX follow-up backlog items. |
| GOV-ARCH-001 | Approve `docs/architecture/architecture-and-trust-boundaries.md` as the architecture and trust-boundary baseline | Russ / Rusty Frink Desiato | 2026-05-28 | Architecture and trust boundaries for Moose Inventory | Approval covers architecture and trust boundaries only. It does not approve security/privacy design, release, accepted risk, public/compliance claims, future RubyGems publishing, implementation of architecture follow-up backlog items, or repository/package account-management design. |
| GOV-SEC-001 | Approve `docs/security/security-privacy-process.md` as the security and privacy process baseline, with `docs/security/accepted-risk-register.md` approved as the register structure/evidence location | Russ / Rusty Frink Desiato | 2026-05-29 | Security and privacy process for Moose Inventory | Approval covers security/privacy process and the accepted-risk register structure only. It does not approve a release, public/compliance claims, future RubyGems publishing, or acceptance of any proposed/monitored risk. Current accepted-risk register still records no approved accepted risks. |
| GOV-RISK-REG-001 | Approve `docs/security/accepted-risk-register.md` as the maintained accepted-risk register baseline | Russ / Rusty Frink Desiato | 2026-05-29 | Accepted-risk register baseline for Moose Inventory | Approval covers the risk-register document, structure, rules, review cadence, and current proposed/monitored-risk evidence. It does not approve a release, public/compliance claims, future RubyGems publishing, or acceptance of any proposed/monitored risk. Current accepted-risk register still records no approved accepted risks. |
| GOV-MAINT-001 | Approve `docs/maintenance/package-maintenance-and-agent-boundaries.md` as the package maintenance and AI-agent operation-boundary baseline | Russ / Rusty Frink Desiato | 2026-05-29 | Package maintenance process and AI-agent operation boundaries for Moose Inventory | Approval covers routine package-maintenance process, release-readiness stewardship, and AI-agent boundaries only. It does not approve publishing, yanking/deprecating RubyGems versions, changing GitHub/RubyGems settings, accepting risk, public/compliance claims, external disclosures, or future RubyGems publishing. |

## Pending approvals

_No pending approvals are currently recorded._

## Approval rules

Approvals must include:

- decision
- approver
- date
- scope
- conditions or limitations
- follow-up date where relevant

Documents, checklists, audits, and passing tests are evidence. They are not approval unless an approver explicitly records the decision here or in another durable project evidence location.
