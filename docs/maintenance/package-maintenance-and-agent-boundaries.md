# Moose Inventory Package Maintenance Runbook and AI-Agent Boundaries

## Approval status

Status: **Approved package maintenance and AI-agent operation-boundary baseline**

Russ / Rusty Frink Desiato approved this document as the package maintenance and AI-agent operation-boundary baseline for Moose Inventory on 2026-05-29. Approval reference: `GOV-MAINT-001`.

This document defines the routine package-maintenance runbook and AI-agent operation boundaries for Moose Inventory.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.
- `GOV-UX-001`: `docs/ux/cli-workflow-notes.md` is approved as the CLI UX/workflow baseline.
- `GOV-ARCH-001`: `docs/architecture/architecture-and-trust-boundaries.md` is approved as the architecture and trust-boundary baseline.
- `GOV-SEC-001`: `docs/security/security-privacy-process.md` is approved as the security and privacy process baseline.
- `GOV-RISK-REG-001`: `docs/security/accepted-risk-register.md` is approved as the maintained accepted-risk register baseline.
- `GOV-MAINT-001`: this document is approved as the package maintenance and AI-agent operation-boundary baseline.

Related templates:

- `docs/qa/qa-documentation-and-release-gates.md`
- `docs/release/release-readiness.md`
- `docs/release/publishing.md`
- `docs/security/accepted-risk-register.md`

Scope limit: this runbook covers local repository maintenance and release-readiness stewardship. It does not approve publishing a release, yanking/deprecating a gem, accepting risk, changing RubyGems/GitHub account ownership, adding hosted operations, or performing external communications as the project.

## Maintenance principles

- Keep maintenance boring. Boring is the grown-up version of secure.
- Prefer small, reviewable branches with one intent each.
- Keep generated files, local databases, coverage reports, temporary gems, and tool caches out of commits unless intentionally documented.
- Use the full release gate before claiming release readiness.
- Treat dependency, workflow, and release-infrastructure changes as supply-chain-sensitive.
- Evidence is not approval. Tests, scans, and docs support human decisions; they do not replace them.

## Routine maintenance cadence

| Area | Suggested cadence | Evidence / command | Notes |
| --- | --- | --- | --- |
| Ruby dependencies | Monthly, before releases, and when advisories appear | `bundle outdated`, `bundle update <gem>` on scoped branches, `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh` | Prefer targeted updates over broad churn unless doing a planned dependency refresh. |
| Ruby version support | Quarterly and before CI matrix changes | `.github/workflows/ci.yml`, gemspec Ruby requirement, local/CI gate | Changing supported Ruby versions is compatibility work and should be reflected in docs/release notes. |
| GitHub Actions versions | Monthly or when deprecation/security notices appear | Review `.github/workflows/*.yml`, then full gate | Pin or upgrade actions deliberately; review permission and release-token implications. |
| Security tools | Monthly and before releases | `scripts/ci/install_security_tools.sh`, `check_security.sh`, `check_secrets.sh` | If tool availability changes, update release-readiness docs and accepted-risk notes as needed. |
| Vulnerability advisories | Before releases and when alerts arrive | OSV, `bundler-audit`, `osv-scanner`, GitHub advisory evidence when available | Triage reachability and severity; do not ship unresolved critical/high without explicit risk acceptance. |
| Package metadata | Before releases and dependency bumps | `moose-inventory.gemspec`, `scripts/ci/package_sanity.sh` | Review executable, files, MFA metadata, dependency ranges, required Ruby, license, and homepage/source links. |
| Release workflow and RubyGems publishing path | Before each release | `.github/workflows/release.yml`, `docs/release/publishing.md`, GitHub `release` environment status | Confirm trusted publishing assumptions before tagging. |
| Documentation drift | After user-facing changes and before releases | Documentation QA checklist | Keep README, requirements, UX, architecture, security, QA, and release docs aligned. |

## Standard maintenance workflow

1. Start from a clean `master` branch.
2. Create a focused branch for the maintenance item.
3. Inspect the relevant docs, code, workflows, and backlog entries before editing.
4. Make the smallest coherent change.
5. Update docs and backlog records in the same branch when behavior, process, or risk posture changes.
6. Run the smallest meaningful gate while developing.
7. Run `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh` before merge when the work touches dependencies, package metadata, release tooling, security posture, or process evidence.
8. Commit the branch work with a clear message.
9. Merge back to `master` deliberately.
10. Rerun the meaningful gate after merge.
11. Report what changed, verification evidence, new backlog items, blockers, and whether `master` is clean/ahead of origin.

## Dependency update runbook

Use this for RubyGem dependency updates and dependency-range changes.

1. Identify the reason for the update:
   - vulnerability fix;
   - compatibility with supported Ruby versions;
   - routine maintenance;
   - toolchain or CI support.
2. Review current dependency constraints in `moose-inventory.gemspec`, `Gemfile`, and `Gemfile.lock`.
3. Prefer a targeted update:

   ```bash
   bundle update <gem-name>
   ```

4. For security fixes, capture advisory identifiers and affected versions.
5. Run:

   ```bash
   MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
   ```

6. Review whether package metadata or docs need updates.
7. If a critical/high issue remains reachable, block release unless a human records accepted risk.
8. Commit `Gemfile.lock` and any intentional constraint/doc updates together.

Do not:

- hide dependency warnings by weakening gates;
- switch package sources without approval;
- add network/runtime dependencies without architecture/security review;
- broaden dependency ranges purely to silence tooling.

## Ruby and CI action update runbook

Use this when changing Ruby support or GitHub Actions dependencies.

1. Review `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `moose-inventory.gemspec`, and docs.
2. For Ruby support changes, confirm the version is supported by required native/database gems.
3. For action upgrades, review changelogs for permission, token, runtime, and behavior changes.
4. Keep release workflow permissions minimal.
5. Do not add publish secrets unless manual fallback is explicitly approved; trusted publishing/OIDC is the baseline.
6. Run the full local gate and wait for CI evidence when pushed.
7. Update release docs if release workflow behavior changes.

## Vulnerability triage runbook

Use highest applicable severity from `docs/security/security-privacy-process.md`.

1. Capture the source:
   - OSV/advisory ID;
   - `bundler-audit` finding;
   - `osv-scanner` result;
   - GitHub security advisory;
   - manual report.
2. Identify affected component, version, and reachability:
   - runtime dependency;
   - development/test dependency;
   - release workflow/tooling;
   - documentation/example only.
3. Determine impact:
   - credential exposure;
   - arbitrary code execution;
   - data corruption/loss;
   - package compromise;
   - denial of service;
   - process/tooling hardening gap.
4. Choose disposition:
   - fix immediately;
   - patch dependency or workflow;
   - document non-reachability;
   - defer as backlog for low/medium findings;
   - request accepted-risk approval when release would proceed with known risk.
5. For suspected credential exposure or package compromise, stop release activity and escalate to a human maintainer.
6. Record evidence in docs, backlog, or security notes as appropriate.

Release blocking rule: unresolved critical/high findings block release unless an explicit human accepted-risk decision exists in `docs/security/accepted-risk-register.md`.

## GitHub and RubyGems release-infrastructure stewardship

Maintainers should periodically confirm:

- repository owner/name remain `RusDavies/moose-inventory` for trusted publishing;
- release workflow filename remains `release.yml`;
- RubyGems trusted publisher uses the `release` environment;
- GitHub `release` environment protection rules are understood before release;
- workflow permissions remain least-privilege;
- no RubyGems API key is stored in GitHub secrets for normal trusted publishing;
- manual publishing credentials, if ever used, remain local, scoped, and protected with `0600` permissions.

Agents may document observed configuration and prepare checklists, but changing GitHub/RubyGems account settings, repository ownership, trusted-publisher setup, secrets, or environment protections requires explicit human approval.

## Release recovery runbook

Use `docs/qa/qa-documentation-and-release-gates.md` for full yank/deprecation/rollback templates. Summary:

1. Stop further release activity.
2. Preserve evidence: version, tag, commit, workflow run, RubyGems URL, install output, and failure symptoms.
3. Determine whether this is:
   - ordinary regression;
   - security issue;
   - credential exposure;
   - package compromise;
   - publishing/workflow failure;
   - RubyGems propagation false negative.
4. If users are affected, prepare a patch release on a new version number.
5. Do not yank, deprecate, publish an advisory, or manually push a gem without explicit human maintainer approval.
6. Update release docs, accepted-risk register, audit notes, or backlog based on the outcome.

## AI-agent permitted maintenance actions

AI agents may perform these actions when working inside this repository and following the git workflow:

- inspect repository files, docs, tests, and local git history;
- create focused branches;
- edit code, tests, docs, and process files for scoped tasks;
- run local tests, linters, package sanity checks, security scans, and documentation checks;
- update `BACKLOG.md` with discovered follow-up work;
- add or update local runbooks, templates, and evidence docs;
- commit and merge local branches after verification;
- report status and evidence in the project Discord channel;
- prepare release checklists, drafts, and recommendations.

## AI-agent actions requiring explicit human approval

Agents must ask first before:

- pushing to remote branches or tags unless Russ explicitly requests it;
- creating, moving, or deleting release tags;
- publishing to RubyGems;
- yanking or deprecating RubyGems versions;
- changing RubyGems owners, trusted publishers, MFA settings, or package credentials;
- changing GitHub repository settings, branch protections, release environment protections, secrets, deploy keys, or ownership;
- adding/removing CI secrets or credentials;
- accepting security/privacy/release risk;
- making public security disclosures or advisories;
- sending external communications as the project or maintainer;
- introducing hosted-service behavior, telemetry, or new external network behavior;
- deleting repository history or performing destructive cleanup beyond recoverable local temporary files.

## AI-agent no-go zones

Agents must not:

- exfiltrate, print, commit, or store credentials;
- bypass failed security checks by weakening gates without explicit review and approval;
- treat proposed/monitored risks as accepted risks;
- publish a release because checks passed;
- use manual RubyGems credentials unless a human maintainer explicitly chooses that fallback;
- modify account-level GitHub or RubyGems settings autonomously;
- rewrite public history without explicit approval;
- make legal/compliance claims beyond the approved docs;
- represent the project as having hosted operations, RBAC, tenant isolation, telemetry guarantees, or compliance certifications not explicitly approved.

## Maintenance report template

```markdown
## Maintenance report

Item:
Branch:
Commit / merge:
Date:

Changed:
- 

Verification:
- [ ] Small gate:
- [ ] Full gate, if required:
- [ ] Documentation reviewed:

Risk / security notes:
- Accepted-risk register changed: yes/no
- New findings:
- Human approvals required:

Backlog:
- New items added:
- Burndown:

Status:
- `master` clean:
- Ahead/behind origin:
- Next recommended item:
```

## Current known operational follow-ups

- Confirm GitHub `release` environment protection rules with maintainers before a future release.
- Decide whether public `SECURITY.md` vulnerability intake should be added.
- Complete destructive-command confirmation work before expanding destructive workflows.
- Evaluate signed provenance or attestations later if target users require more than RubyGems trusted publishing.
