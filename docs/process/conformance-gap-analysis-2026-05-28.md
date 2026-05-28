# Moose Inventory Process Conformance Gap Analysis — 2026-05-28

## Scope

This analysis compares Moose Inventory against the updated workspace product-process guidance, especially:

- `SOFTWARE_PRODUCT_DEVELOPMENT_PROCESS.md`
- `TAILORING_GUIDE.md`
- `GOVERNANCE_AND_APPROVALS.md`
- requirements, architecture, security, QA, release, operations, and documentation guidance

The key governance rule for this audit is explicit: **a document existing in the repository is evidence, not approval**. Approval requires a durable recorded decision with approver, date, scope, and limitations.

## Recommended tailoring classification

Recommended classification for approval: **Class 4 — Public / Production / Commercial Product**, target profile **Software Library / Package**.

Rationale:

- Moose Inventory is a public RubyGem published to RubyGems.
- It is intended for real Ansible inventory workflows and can affect infrastructure operations.
- It handles database configuration, environment-specific inventory state, package publishing, CI, and release automation.
- It is not a hosted service or operated runtime, so the software-library/package target profile excludes normal service monitoring, alert routing, backup/restore operations, and runtime incident runbooks unless a future hosted/runtime component is added.
- Library/package concerns remain mandatory: API/CLI compatibility, release integrity, trusted publishing, supply-chain security, vulnerability intake, security patching, maintainer ownership, and developer/user documentation.

Approval status: **not approved**. This is a recommendation prepared for Russ or another authorized product owner to approve, revise, or reject.

## Current evidence inventory

| Area | Existing evidence | Approval status | Gap |
| --- | --- | --- | --- |
| Tailoring/classification | This analysis recommends Class 4 + Software Library/Package | Not approved | Need durable tailoring decision record |
| Product framing | README explains purpose/use with Ansible | Not approved as product baseline | Need concise product brief/framing note with goals, users, non-goals, success criteria |
| Requirements | README, CLI behavior, tests, backlog | Not approved as requirements baseline | Need requirements/acceptance baseline covering CLI, DB, Ansible integration, package/release, security, compatibility |
| UX/product design | CLI help/README/tests | No UX approval | For CLI package, need lightweight CLI workflow/UX notes rather than wireframes |
| Architecture | Code and README describe behavior; release docs cover publishing | Not approved | Need architecture overview for CLI/package, DB adapters, schema migrations, Ansible integration, trust boundaries, and release pipeline |
| Security/privacy | Security audit reports, gitleaks/OSV/bundler-audit gates, README secret guidance | Audit evidence exists, not release/security approval | Need maintained threat model, data classification, secrets/logging model, vulnerability-intake/security patch policy, accepted-risk register |
| Compliance readiness | Not applicable as enterprise product claim today | No compliance claims approved | Need explicit non-goal/claim boundary so no SOC 2/ISO/ISO-style readiness is implied |
| Documentation planning | README and release docs exist | No documentation QA/sign-off record | Need documentation plan/checklist for user/developer/release/security docs |
| QA/test evidence | `scripts/check.sh`, RSpec, SimpleCov, RuboCop, permission check, OSV, bundler-audit, gitleaks, package sanity, CI matrix | Test evidence exists per run, not process approval | Need QA plan mapping gates to requirements and release criteria |
| Release security gate | Release readiness/publishing docs and security audits exist | No formal release approval template/current gate record | Need release-security gate checklist, accepted-risk disposition, release approval fields |
| Operations/maintenance | Release docs, CI/release workflows, security audits | Partial | Need package-maintenance runbook: owner, release infrastructure, vulnerability intake, update cadence, release/yank/deprecation path, AI-agent maintenance boundaries |
| AI-agent operation boundaries | Workspace/git workflow exists outside repo; no repo-local boundary | Not approved | Need repo-local boundaries for agent-assisted maintenance/release prep, especially no publishing/release/accepted-risk decisions without human approval |
| Backlog/evidence practice | BACKLOG.md is extensive and current | Partial | Need process backlog acceptance criteria/approval notes on process items |

## Gap analysis

### 1. Governance and approvals

The repository has strong implementation evidence but little explicit governance evidence. Release docs describe trusted publishing and successful v2.0 publishing, but they do not by themselves approve future releases, accepted risks, classification, or product direction.

Gaps:

- No recorded tailoring/classification approval.
- No approval register or decision-record location specific to the repo.
- No explicit list of human-owned decisions vs agent-executable maintenance work.
- No accepted-risk register, even if currently empty.

Impact: future agents can confuse “documented process” with “approved gate,” which is exactly the paper goblin we are trying not to feed.

### 2. Product and requirements baseline

README and tests provide a de facto behavioral contract, but there is no approved product/requirements baseline.

Gaps:

- No concise product brief stating target users, use cases, non-goals, and success criteria.
- No requirements spec separating functional, non-functional, security, package/release, compatibility, and documentation requirements.
- No explicit public API/CLI compatibility and deprecation policy beyond existing behavior/tests.

Impact: development can continue, but release readiness and change impact rely on tribal knowledge plus tests rather than an approved baseline.

### 3. CLI UX/workflow design

Because Moose Inventory is a CLI/package, full visual UX wireframes are not needed. However, the updated process still expects workflow/usability/trust states where user-facing workflows exist.

Gaps:

- No lightweight CLI workflow/UX note for core workflows, destructive operations, dry-run behavior, machine-readable output, error states, accessibility/readability expectations, and trust/confirmation boundaries.
- No UX approval record for CLI workflow conventions.

Impact: output compatibility is well tested, but UX decisions are implicit.

### 4. Architecture and trust boundaries

The code has improved architecture, and release docs capture publishing mechanics, but there is no architecture overview matching the updated guidance.

Gaps:

- No architecture overview for CLI layers, operation objects, DB schema/migrations, adapters, Ansible plugin/shim integration, audit log, import/export, and release pipeline.
- No data model/trust-boundary diagram or written equivalent.

Impact: maintainers can infer architecture from code, but future maintainers/agents lack a clear evidence artifact.

### 5. Security/privacy and vulnerability operations

Security audit evidence is strong for recent work. The missing piece is not “did we scan?” but “what is the maintained security model?”

Gaps:

- No maintained threat model/abuse-case document.
- No data classification/data-flow note for local inventory DBs, config files, environment passwords, audit logs, and package artifacts.
- No vulnerability intake/security patch policy.
- No explicit release accepted-risk register/disposition model.
- Secret scanning on GitHub is documented as unavailable/disabled in audit evidence; local gitleaks compensates, but the residual posture should be tracked.

Impact: current gates are good, but future security decisions lack durable process scaffolding.

### 6. QA and documentation QA

The automated gate is strong and repeatable. The process gap is mapping those checks to requirements/release criteria and documenting documentation QA.

Gaps:

- No QA plan that maps RSpec/SimpleCov/RuboCop/permission/security/package checks to release criteria.
- No documentation QA checklist for README, release docs, examples, Ansible plugin docs, and security claims.
- No known-issues/accepted-exceptions template for release candidates.

Impact: checks are real, but release evidence is less reviewable than it should be.

### 7. Release and package operations

Trusted publishing and release docs are good. Updated guidance expects approval records, rollback/yank/deprecation plans, and post-release review.

Gaps:

- No formal release checklist template with approver/date/scope/conditions.
- No release security gate template/current gate record.
- No explicit gem yank/deprecation/rollback decision path.
- No post-release review template or cadence.

Impact: publishing mechanics are documented, but release governance is incomplete.

### 8. Operations profile for a library/package

Moose Inventory does not need hosted-service monitoring, alerting, backup/restore, or runtime incident operations unless it later ships an operated service. It does need package maintenance operations.

Gaps:

- No maintainer operations runbook for dependency update cadence, vulnerability triage, CI/release failures, RubyGems/GitHub account stewardship, trusted publishing maintenance, and release recovery.
- No AI-agent operation boundaries for repository maintenance and release preparation.

Impact: routine maintenance remains doable, but not yet process-conformant under the updated package-maintenance and AI-agent guidance.

## Proposed remediation plan

### Phase 1 — Governance baseline and tailoring

1. Create `docs/governance/approval-register.md` or equivalent.
2. Record proposed Class 4 + Software Library/Package tailoring decision as **pending approval**.
3. Define human-owned decisions: product direction, release approval, accepted risks, RubyGems publishing, compliance/public claims, destructive repo/package actions.
4. Define agent-executable work: local docs/code/test changes, evidence gathering, draft release notes/checklists, non-public internal backlog work.

Exit criteria: Russ or delegated approver explicitly approves or revises the tailoring decision.

### Phase 2 — Product and requirements baseline

1. Add a concise product brief.
2. Add requirements/acceptance criteria for CLI behavior, DB backends, Ansible integration, import/export, dry-run/plan, audit log, release/package integrity, compatibility, and documentation.
3. Mark requirements as draft until approved.

Exit criteria: requirements baseline approved or explicitly left draft with blockers tracked.

### Phase 3 - Architecture, security, and trust boundaries

1. Add architecture overview and data/trust-boundary notes.
2. Add threat model/data classification/secrets-handling notes.
3. Add vulnerability intake/security patch policy and accepted-risk register.

Exit criteria: architecture/security baseline reviewed; unresolved risks tracked.

### Phase 4 — QA, documentation, and release gates

1. Add QA plan mapping current `scripts/check.sh` gates to process expectations.
2. Add documentation plan and documentation QA checklist.
3. Add release checklist and release security gate template with approval fields.
4. Add package rollback/yank/deprecation path and post-release review template.

Exit criteria: next release can produce a complete evidence packet without reconstructing process from commit history and vibes.

### Phase 5 — Maintenance/agent boundaries

1. Add package maintenance runbook.
2. Add AI-agent operation boundaries for repo maintenance, release prep, and explicit no-go zones.
3. Add maintenance cadence reminders/backlog items for dependencies, Ruby versions, CI actions, security scans, and docs review.

Exit criteria: maintainers and agents can safely inspect, patch, prepare releases, and know when to stop for human approval.

## Current launch/release posture

Moose Inventory has strong automated verification and trusted-publishing evidence, but under the updated process it is **not process-conformant for a future release** until at least tailoring, release approval, accepted-risk disposition, documentation QA, and release-security gate evidence are recorded for that release.

This does not invalidate prior releases; it identifies the gap between current repository evidence and the updated workspace process baseline.
