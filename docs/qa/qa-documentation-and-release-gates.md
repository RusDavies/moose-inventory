# Moose Inventory QA, Documentation QA, and Release Gates

## Approval status

Status: **Draft - maintained gate template**

This document defines reusable QA, documentation-QA, and release-gate templates for Moose Inventory. It maps the local verification gate to the approved requirements baseline and adds human-review checkpoints for release decisions.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.
- `GOV-UX-001`: `docs/ux/cli-workflow-notes.md` is approved as the CLI UX/workflow baseline.
- `GOV-ARCH-001`: `docs/architecture/architecture-and-trust-boundaries.md` is approved as the architecture and trust-boundary baseline.
- `GOV-SEC-001`: `docs/security/security-privacy-process.md` is approved as the security and privacy process baseline.
- `GOV-RISK-REG-001`: `docs/security/accepted-risk-register.md` is approved as the maintained accepted-risk register baseline.

Scope limit: this document is a QA/release evidence template. It does not approve a release, public/compliance claim, RubyGems publishing, accepted risk, new feature scope, or future architecture/security change.

## Gate principles

- Evidence is not approval. Passing checks support a release decision; they do not make the decision.
- Release decisions remain human-owned.
- Every exception must be either fixed, deferred as explicit backlog work, or accepted through `docs/security/accepted-risk-register.md` when it is security/privacy/release risk.
- A release candidate should be traceable to requirements, tests, documentation, security scans, package sanity, and rollback/recovery notes.
- Network-dependent security checks may fail closed. If the failure is environmental rather than a finding, record the failed check, rerun when available, and do not publish until the gate is either passing or explicitly accepted.

## Local gate mapping

`./scripts/check.sh` is the default local release-readiness gate. Run with security tools required for release evidence:

```bash
MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
```

| Gate step | Evidence produced | Requirement / release criteria supported | Release interpretation |
| --- | --- | --- | --- |
| `bundle exec rspec --format progress` | Automated spec result and coverage report | CLI, CFG, DB, INV, DRY, SNAP, DOC, AUD, TAG, ANS, CI, COMPAT, DOCS acceptance criteria | Required passing evidence for supported behavior. Any failure blocks release unless a human records an explicit exception. |
| `scripts/ci/check_rubocop.sh` | RuboCop result for Ruby source, executable loader, scripts, specs, and gemspec | COMPAT and maintainability expectations; release quality hygiene | Required passing evidence. Style failures indicate unreviewed code-quality drift. |
| `git diff --check` | Whitespace/conflict-marker check | Documentation/source hygiene and merge-safety expectations | Required passing evidence. Failure blocks release until fixed. |
| `scripts/ci/check_permissions.sh` | Tracked executable permission allow-list check | PKG and release-integrity expectations | Required passing evidence. Unexpected executables are potential packaging/security drift. |
| `scripts/ci/check_security.sh` | OSV batch query, `bundler-audit`, and optional/required `osv-scanner` lockfile/source scan | SEC and PKG dependency/security acceptance criteria | Required passing evidence for release. Critical/high findings block release unless explicitly accepted by a human. |
| `scripts/ci/check_secrets.sh` | `gitleaks` filesystem scan with redaction | SEC secrets-handling criteria | Required passing evidence for release. Any true secret finding requires cleanup and rotation outside Moose Inventory. |
| `scripts/ci/package_sanity.sh` | Built gem, metadata inspection, required packaged files, CLI version smoke | PKG release-integrity criteria | Required passing evidence that the packaged artifact contains expected entrypoints and metadata. |

## Documentation QA checklist

Use this before release and after material user-facing changes.

```markdown
## Documentation QA checklist

Release candidate / commit:
Reviewer:
Date:

Required docs:
- [ ] `README.md` reflects current supported CLI workflows and examples.
- [ ] `docs/product/requirements-baseline.md` still matches intended behavior, or proposed changes are recorded for approval.
- [ ] `docs/ux/cli-workflow-notes.md` still matches command behavior and output conventions.
- [ ] `docs/architecture/architecture-and-trust-boundaries.md` still matches implementation and release flow.
- [ ] `docs/security/security-privacy-process.md` still matches security/privacy posture.
- [ ] `docs/security/accepted-risk-register.md` is reviewed and current.
- [ ] `docs/release/publishing.md` and `docs/release/release-readiness.md` match the actual release workflow.

Content checks:
- [ ] Examples avoid real infrastructure, real credentials, real hostnames, and private data.
- [ ] Snapshot/import/export examples warn that inventory data can be sensitive where relevant.
- [ ] Database credential examples prefer `password_env` over plaintext `password`.
- [ ] Destructive or high-risk workflows show dry-run/confirmation expectations where relevant.
- [ ] Release notes distinguish evidence from approval.
- [ ] Known limitations and non-goals are visible enough for users.
- [ ] New or changed options include machine-readable output implications where relevant.

Evidence:
- [ ] Documentation diff reviewed.
- [ ] Link/path references checked by inspection or tooling.
- [ ] No stale version numbers, release tags, or command output examples remain.
- [ ] Follow-up documentation gaps added to `BACKLOG.md`.
```

## Release readiness checklist

Use this for every release candidate before creating a `v*` tag.

```markdown
## Release readiness checklist

Release version:
Release candidate commit:
Reviewer / release owner:
Date:

Source state:
- [ ] `git checkout master` completed.
- [ ] `git pull --ff-only origin master` completed.
- [ ] `git status --short --branch` is clean and on the expected branch.
- [ ] Version in `lib/moose_inventory/version.rb` matches the intended release.
- [ ] Version is greater than the latest published RubyGems version.
- [ ] Changelog/release notes drafted if maintainers want public notes.

Requirement and QA evidence:
- [ ] Material changes map to approved requirements or have approval/backlog records.
- [ ] `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh` passed.
- [ ] Documentation QA checklist completed.
- [ ] Known compatibility impact reviewed.
- [ ] Generated artifacts, local databases, coverage reports, and temporary files are not committed unless intentional.

Security and risk evidence:
- [ ] Release security gate completed.
- [ ] Accepted-risk disposition completed.
- [ ] No unresolved critical/high findings remain unless explicitly accepted.
- [ ] Secret-scan results reviewed; true positives cleaned and rotated outside Moose Inventory.
- [ ] Package sanity passed for the gem artifact.

Publishing readiness:
- [ ] GitHub Actions CI is green for the release commit.
- [ ] RubyGems trusted publishing setup is still expected to use repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`.
- [ ] Required GitHub `release` environment approvals, if any, are known to the release owner.
- [ ] Manual RubyGems publishing fallback is not used unless trusted publishing is unavailable and a RubyGems owner explicitly approves.

Release decision:
- [ ] Human approver:
- [ ] Approval reference / message:
- [ ] Tag to create:
- [ ] Release notes location:
```

## Release security gate template

```markdown
## Release security gate

Release version:
Release candidate commit:
Reviewer:
Date:

Automated security checks:
- [ ] OSV batch query passed.
- [ ] `bundle-audit check --update` passed.
- [ ] `osv-scanner` lockfile/source scan passed with `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1`.
- [ ] `gitleaks detect --no-git --source . --config .gitleaks.toml --redact --no-banner --log-level warn` passed.
- [ ] Package sanity check passed.

Manual review:
- [ ] Dependency changes reviewed for reachability and release impact.
- [ ] GitHub Actions workflow changes reviewed for permission, token, and publishing risk.
- [ ] Gemspec/package metadata reviewed for MFA, executable, file list, and dependency changes.
- [ ] Config, database, import/export, audit, and release docs reviewed for secret/privacy leakage.
- [ ] Any new external network behavior is documented and approved.

Findings:
- Critical findings:
- High findings:
- Medium findings:
- Low findings:

Disposition:
- [ ] All critical/high findings fixed, or accepted risk recorded.
- [ ] Medium/low findings are fixed, deferred to backlog, or accepted as appropriate.
- [ ] No credentials or private inventory data are present in committed files, logs, docs, examples, or release artifacts.
```

## Accepted-risk disposition template

Use this before release, even when there are no accepted risks.

```markdown
## Accepted-risk disposition

Release version:
Release candidate commit:
Reviewer:
Date:

Register reviewed:
- [ ] `docs/security/accepted-risk-register.md` reviewed.
- [ ] Accepted risks are current and within review date/trigger.
- [ ] Proposed/monitored risks are not being treated as accepted by accident.
- [ ] Any release-blocking proposed/monitored risk has a human decision.

Accepted risks shipping in this release:
- Risk ID:
  - Scope:
  - Severity:
  - Why still acceptable for this release:
  - Compensating controls:
  - Approver / approval reference:

New risk decisions required:
- Risk ID or short name:
  - Decision needed:
  - Blocker status:
  - Owner:

Outcome:
- [ ] No accepted risks ship in this release.
- [ ] Accepted risks ship only within documented scope.
- [ ] Release is blocked pending risk decision.
```

## Package yank, deprecation, and rollback path

RubyGems packages cannot be rolled back in place like a service deployment. Recovery is versioned and human-owned.

### If a release is bad but not security-sensitive

1. Stop further release activity.
2. Record the affected version, tag, workflow run, and observed issue.
3. Decide whether users should keep using the previous version or upgrade to a patch.
4. Prepare and verify a patch release on a new version number.
5. Publish the patch through trusted publishing.
6. Add release notes explaining the fix and impact at an appropriate detail level.

### If a release exposes a security issue or secret

1. Stop release activity and preserve evidence.
2. Identify whether credentials, private inventory data, package integrity, or user safety is affected.
3. Rotate exposed credentials outside Moose Inventory where applicable.
4. Decide with a human maintainer whether to yank, deprecate, patch, or publish an advisory.
5. Prepare the smallest safe patch release and run the full release gate.
6. Publish via trusted publishing when approved.
7. Update `docs/security/accepted-risk-register.md`, security audit notes, or incident notes as appropriate.

### RubyGems yanking/deprecation notes

- Yanking removes a version from normal installation resolution but does not erase every copy already downloaded, cached, mirrored, or vendored.
- Deprecation/advisory communication may be more useful than yanking when users need migration context.
- Never yank or deprecate a gem version without explicit human maintainer approval.
- Manual RubyGems credentials, if used in an emergency, must not be committed or pasted into logs.

## Post-release review template

Run after the workflow completes and published-version verification is available.

```markdown
## Post-release review

Release version:
Release tag:
Release commit:
Workflow run:
Reviewer:
Date:

Publishing outcome:
- [ ] `release.yml` completed successfully, or failure is explained below.
- [ ] Published version appears in `gem info moose-inventory --remote --all`.
- [ ] Fresh install test completed where practical.
- [ ] `moose-inventory --help` or equivalent smoke check completed from installed gem.

Evidence links / references:
- CI run:
- Release workflow run:
- RubyGems version URL:
- Release notes / tag:

Problems observed:
- Workflow false negatives:
- RubyGems propagation delays:
- Install/smoke-test failures:
- User-visible documentation gaps:
- Security/risk follow-up:

Follow-up actions:
- [ ] Backlog items added for any release friction.
- [ ] Accepted-risk register updated if any risk decision changed.
- [ ] Release docs updated if the process diverged from documentation.
- [ ] Maintainers notified of release outcome.
```

## Current release blockers and follow-ups

These templates do not make the current repository release-ready by themselves. Before the next release, maintainers should still review:

- confirmed GitHub `release` environment protection rules;
- any active security-audit findings or dependency advisories;
- whether public `SECURITY.md` vulnerability intake should be added;
- whether destructive-command confirmation is required before broadening destructive workflows;
- whether package provenance beyond RubyGems trusted publishing is needed for the intended audience.
