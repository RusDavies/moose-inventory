# Moose Inventory CLI UX and Workflow Notes

## Approval status

Status: **Approved CLI UX/workflow baseline**

Approval reference: `GOV-UX-001` in `docs/governance/approval-register.md` approves this document as the CLI UX/workflow baseline for Moose Inventory.

Approved references:

- `GOV-TAILOR-001`: Moose Inventory is approved as Class 4 with target profile Software Library / Package.
- `GOV-PRODUCT-001`: `docs/product/product-brief.md` is approved as the product-framing baseline.
- `GOV-REQ-001`: `docs/product/requirements-baseline.md` is approved as the requirements and acceptance criteria baseline.

Scope limit: this approval covers command-line workflows and interaction conventions only. It is not architecture approval, security/privacy design approval, release approval, accepted-risk approval, public/compliance-claim approval, RubyGems publishing approval, or implementation approval for the UX follow-up backlog items.

## UX posture

Moose Inventory is a command-line tool and RubyGem, so its UX baseline is not wireframes or visual mockups. The appropriate UX artifact is a workflow and interaction convention baseline for CLI users, automation users, reviewers, and maintainers.

Primary UX priorities:

1. Make inventory-changing actions explicit, reviewable, and hard to mistake for read-only actions.
2. Preserve existing command names, output shape, and wording where users or tests may depend on them.
3. Keep machine-readable output parseable and stable enough for automation.
4. Give clear, actionable error messages before any write occurs when inputs/options are invalid.
5. Keep safety controls visible: transactions, dry-run, plan output, validation, doctor checks, and audit history.

## User personas and interaction modes

### CLI operator

A human operator uses `moose-inventory` directly to inspect and change inventory state.

UX needs:

- discoverable help
- predictable command families
- readable progress output
- clear success/failure states
- safe review before mutation

### Automation/review consumer

A script, CI job, or reviewer consumes machine-readable output from list/get/doctor/export/dry-run plan commands.

UX needs:

- parseable YAML/JSON/pjson
- non-zero status for failed checks/findings where documented
- stable keys and event structure
- no secret leakage in examples/output

### Maintainer/release reviewer

A maintainer checks behavior, documentation, release evidence, and compatibility.

UX needs:

- regression tests for output contracts
- README examples matching supported behavior
- clear approval boundaries for breaking changes
- process evidence distinguishing checks from approval

## Core workflows

### 1. Discover commands

Workflow:

1. User runs top-level or nested help.
2. CLI displays available commands/options.
3. User chooses a command family such as `host`, `group`, `db`, `audit`, `doctor`, `import`, or `export`.

UX expectations:

- Help must be available at top-level and command-family levels.
- Help examples should be accurate enough to copy/adapt.
- New command families should follow existing README/help style.

### 2. Select configuration and environment

Workflow:

1. User relies on config discovery or passes `--config <FILE>`.
2. User relies on `general.defaultenv` or passes `--env <SECTION>`.
3. CLI initializes the configured database context.

UX expectations:

- Missing config, missing environment, and invalid DB config errors should fail before mutation.
- Error messages should name the missing/invalid element when practical.
- Docs should steer users toward `password_env` rather than plaintext `password`.

### 3. Inspect inventory

Workflow:

1. User runs list/get commands for hosts/groups/variables/tags.
2. User optionally passes `--format yaml|json|pjson`.
3. CLI returns current state without mutation.

UX expectations:

- Read-only commands should not create, repair, or migrate data implicitly unless explicitly documented.
- Machine-readable formats should remain parseable and consistent.
- Empty results should be explicit rather than misleading.

### 4. Mutate inventory safely

Workflow:

1. User chooses a mutating command: add/remove hosts/groups, variables, tags, associations, or child relationships.
2. User optionally previews with `--dry-run` or `--dry-run --plan-format`.
3. CLI validates inputs/options before writes.
4. CLI applies changes transactionally when not dry-run.
5. CLI reports progress, warnings, success/failure, and audit evidence where applicable.

UX expectations:

- Mutating commands must be visually distinguishable from read-only workflows through command naming, progress output, and documentation.
- Invalid option combinations, such as `--plan-format` without `--dry-run`, fail before mutation.
- Dry-run output must not imply changes were applied.
- Real mutation output should preserve existing output contracts unless a breaking change is approved.

### 5. Review planned changes

Workflow:

1. User runs a mutating command with `--dry-run`.
2. CLI renders planned progress and ends with `Dry run complete. No changes applied.`
3. User optionally requests `--plan-format yaml|json|pjson` for automation review.

UX expectations:

- Dry-run should use the same conceptual progress path as a real mutation.
- Dry-run should not write inventory, audit records, schema state, or automatic cleanup associations.
- Plan output should include ordered event types and payloads suitable for review tools.
- Human-readable dry-run output should remain easy to compare with real command output.

### 6. Validate health

Workflow:

1. User runs `moose-inventory doctor`.
2. CLI performs read-only checks.
3. CLI reports no issues or lists findings with severity/check identifiers.
4. CLI exits non-zero when findings are present.

UX expectations:

- Findings should be actionable and identify affected subject when practical.
- Machine-readable doctor output should be suitable for CI gates.
- Doctor should not silently fix inventory; repairs should remain explicit user actions.

### 7. Import/export snapshots

Workflow:

1. User exports inventory for review, backup, migration, or automation.
2. User imports a YAML/JSON snapshot.
3. CLI validates before writing and applies additive/update-oriented changes only.

UX expectations:

- Export should be read-only.
- Import validation failures should avoid partial writes.
- Additive import semantics must be documented clearly.
- Destructive sync/restore semantics must not be introduced without separate requirements, UX, recovery, and approval records.

### 8. Review audit history

Workflow:

1. User runs `audit list` with optional format/limit.
2. CLI returns append-only evidence for successful mutating commands.

UX expectations:

- Audit output should help explain what changed, when, by whom/tooling, and against what target.
- Audit output is accountability/debug evidence, not rollback by itself.
- Dry-runs should not appear as mutation audit records.

## Destructive and high-risk operations

High-risk CLI areas include:

- host/group removal
- recursive group deletion
- child-group cleanup with orphan deletion
- variable removal
- snapshot import into populated databases
- schema migration
- backup/restore-adjacent workflows
- future destructive snapshot sync/restore features, if ever approved

UX requirements for high-risk operations:

1. The command name/options must make destructive intent visible.
2. Documentation must describe mutation scope and notable cleanup behavior.
3. `--dry-run` should be available for documented mutating workflows where supported.
4. Invalid inputs/options must fail before writes.
5. Real writes should be transactional where practical.
6. Future destructive restore/sync behavior requires a separate UX design and approval record.

## Error states and messaging

Expected error behavior:

- fail early before mutation when arguments/options/config are invalid
- name the invalid option/value where practical
- distinguish usage errors from database/runtime failures
- preserve existing exact error strings where tests or downstream users rely on them
- avoid exposing secrets in errors

Known UX improvement area:

- Read-only console parsing currently has blunt whitespace splitting and validation limitations. This remains tracked in the code-improvement backlog and should be improved without turning the console into a mutating interface.

## Accessibility and readability expectations

For a CLI, accessibility/readability means:

- plain text that works in ordinary terminals
- no required color-only signal
- stable indentation for progress output
- concise severity/check IDs for doctor findings
- machine-readable alternatives for automation and assistive tooling
- examples that can be copied without hidden state or secrets
- readable failure messages rather than stack traces for ordinary user errors

## Machine-readable output conventions

Machine-readable output is automation-facing UX.

Expectations:

- JSON/YAML/pjson structures should remain parseable.
- Event/check keys should not be renamed casually.
- New fields should prefer additive compatibility.
- Breaking output changes require approval and migration/release notes.
- Pretty JSON is for humans reviewing structured data; normal JSON/YAML are for scripts and CI.

## Compatibility conventions

Human-readable output is also a compatibility surface when tests, docs, or scripts rely on exact wording.

Expectations:

- Preserve existing wording/newline behavior during refactors unless an intentional change is approved.
- Tests should cover known legacy output contracts, especially around warnings and cleanup behavior.
- README examples should not promise output that the CLI no longer emits.

## UX acceptance checklist

A new or changed CLI workflow is UX-ready when:

- The command path and option names are consistent with existing command families.
- Read vs write behavior is obvious from command naming and docs.
- Invalid inputs/options fail before mutation.
- Mutating behavior is transactional where practical.
- Dry-run/plan behavior exists where required by the requirements baseline.
- Human-readable output is clear and compatible unless an approved breaking change exists.
- Machine-readable output is parseable and compatibility-reviewed.
- README/help examples are updated where user-facing behavior changed.
- Tests cover success, failure, and safety boundaries.
- Any unresolved UX risk is recorded as a backlog item or accepted risk.

## UX decisions recorded from review

These decisions were provided by Russ during review on 2026-05-28. They are captured here as product/UX direction for future implementation, but this draft UX baseline still requires explicit approval through `GOV-UX-001` before it becomes approved UX evidence.

1. Destructive commands should eventually require explicit confirmation unless `--yes` or an equivalent non-interactive acknowledgement is provided.
2. Human-readable output compatibility should be formally versioned, not only machine-readable output compatibility.
3. Read-only console support for quoted names and richer validation through `Shellwords.split` should be prioritized before adding more CLI features.
4. Audit history should remain evidence only; future rollback/change-set UX should not be introduced through audit history.
5. Snapshot import should eventually offer a formal preview/diff mode distinct from command-level dry-run planning, but this is future work and does not block the current UX baseline.

## Open UX questions

No open UX questions remain in this draft. Future questions should be added here only when they are not already represented as a decision, backlog item, or accepted scope limit.
