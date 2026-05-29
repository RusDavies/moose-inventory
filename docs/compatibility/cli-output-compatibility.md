# CLI Output Compatibility Policy

Status: documented baseline for Moose Inventory 2.x maintenance work.

Moose Inventory treats both machine-readable and documented human-readable CLI output as compatibility surfaces. The project does not promise that every diagnostic sentence is permanent forever, but it does promise that output used by scripts, README examples, release gates, or regression specs changes only deliberately.

## Compatibility version

The current CLI output compatibility baseline is **CLI-OUTPUT-v1**.

`CLI-OUTPUT-v1` covers the Moose Inventory 2.x command family and remains in force until a release note explicitly declares a replacement baseline such as `CLI-OUTPUT-v2`.

The compatibility version lives in:

1. this policy document;
2. release notes or release-readiness evidence for releases that preserve or change the baseline;
3. backlog or approval evidence for any accepted breaking output change.

Existing JSON/YAML output is not retrofitted with a top-level version field only to advertise this policy. Adding such a field to legacy shapes could break strict automation consumers. New machine-readable envelopes may include an explicit `schema_version` field when they are designed from the start with versioning.

## Machine-readable output rules

Machine-readable output includes:

- `--format json|yaml|pjson` output for list/get/report commands;
- `export` snapshot output;
- `doctor --format ...` reports;
- `audit list --format ...` results;
- `--dry-run --plan-format json|yaml|pjson` event plans;
- tag list output emitted with `--format`.

Under `CLI-OUTPUT-v1`:

- JSON/YAML/pjson must remain parseable in the declared format.
- Existing top-level keys, nested keys, and event `type` strings should not be renamed or removed without a breaking-change approval.
- New fields are preferred over renamed fields.
- Field ordering is not a machine-readable compatibility guarantee unless a specific command documents ordered event semantics.
- `pjson` is semantically equivalent to `json`; whitespace and indentation are not compatibility guarantees.
- YAML scalar formatting details are not compatibility guarantees when the parsed structure is unchanged.

## Human-readable output rules

Human-readable output includes default progress text, warning summaries, success/failure text, usage errors, README examples, and docs that show command output.

Under `CLI-OUTPUT-v1`:

- Output locked by regression specs is compatibility-protected.
- README examples and documented workflows should remain accurate.
- Refactors should preserve existing wording/newline behavior when practical.
- Intentional user-visible wording changes require test updates and a release-note or backlog explanation.
- Typos, grammar, and clarity fixes are allowed when they do not alter documented automation-facing behavior, but they should still be reviewed as compatibility-impacting changes when specs or README examples change.

Human-readable output is not a recommended automation interface. Scripts should use `--format`, `export`, `audit --format`, or `--plan-format` whenever possible.

## Breaking-change process

A breaking output change is any change that removes, renames, or substantially changes a documented field/event, or intentionally changes protected human-readable output in a way likely to break users or tests.

Breaking output changes require:

1. a backlog item or approval note describing the change and reason;
2. updated regression coverage for the new behavior;
3. README/docs updates;
4. release notes naming the old and new compatibility baseline when the change leaves `CLI-OUTPUT-v1`;
5. migration guidance for automation consumers when machine-readable output changes.

Non-breaking additive fields, new commands, new event types for newly supported behavior, and clearer non-documented diagnostics can ship within `CLI-OUTPUT-v1` when tests and docs are updated.

## Release checklist

Before release, reviewers should confirm:

- the release preserves `CLI-OUTPUT-v1`, or explicitly documents the next compatibility baseline;
- changed machine-readable outputs remain parseable;
- changed human-readable outputs are intentional and covered by specs/docs;
- release notes call out any compatibility-relevant changes.
