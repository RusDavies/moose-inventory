# Snapshot Import Availability Fuzz Audit - 2026-05-29

Repository: `RusDavies/moose-inventory`
Local path: `/home/skippy/.openclaw/workspace/projects/moose-inventory`
Commit audited: `48da0472f8fadb7685777987545d51b4b62eb806`
Version audited: `2.1`
Audit context: follow-up to `code-security-audit` run `3`

## Scope

This pass targeted snapshot import availability and malformed-input behavior for the local CLI import path:

```bash
ruby -Ilib bin/moose-inventory --config spec/config/config.yml import SNAPSHOT.yml --preview
```

The pass used preview mode to keep the fuzz cases non-mutating while still exercising YAML loading, snapshot normalization, validation, and preview generation.

## Cases exercised

| Case | Result | Notes |
| --- | --- | --- |
| Baseline valid snapshot | Pass | Preview completed in 0.127s. |
| Malformed YAML | Graceful rejection | Reported a sanitized `ERROR: Could not parse inventory snapshot ...`. |
| YAML alias | Ungraceful rejection | Rejected safely, but emitted a Ruby/Psych stack trace. |
| Disallowed symbol key / duplicate-normalized-key probe | Ungraceful rejection | Rejected safely, but emitted a Ruby/Psych stack trace before project-level validation. |
| Group cycle | Graceful rejection | Reported `Invalid inventory snapshot: group hierarchy contains a cycle ...`. |
| Unknown child group reference | Graceful rejection | Reported `Invalid inventory snapshot: group ... references unknown child group ...`. |
| 5,000 variable entries | Pass | Preview completed in 0.157s. |
| 250-deep group chain | Pass | Preview completed in 0.142s. |
| 1,000-deep group chain | Pass | Preview completed in 0.187s. |
| 3,000-deep group chain | Pass | Preview completed in 0.306s. |

Raw local artifact: `.openclaw-security-audit/fuzz_snapshot_import_availability_run.json`.

## Finding

### P3 / Low: snapshot import does not sanitize all Psych safe-load exceptions

`Application#import` currently rescues `Psych::SyntaxError` around `YAML.safe_load_file`, but safe-load can also raise other Psych exceptions such as `Psych::AliasesNotEnabled` and `Psych::DisallowedClass` before Moose Inventory's snapshot validator runs.

Observed examples:

- YAML alias payload is rejected because aliases are disabled, but the CLI prints a Ruby/Psych stack trace.
- Symbol-tag payload is rejected because permitted classes are restricted, but the CLI prints a Ruby/Psych stack trace.

Security interpretation:

- The unsafe payloads were rejected, so this is not unsafe deserialization or code execution.
- The issue is availability/UX hardening and minor information disclosure through local stack traces and filesystem/gem paths.
- Reachability is local CLI import of an attacker-supplied or untrusted snapshot file.
- Priority is P3/low because the blast radius is local command failure/noisy logs rather than inventory corruption or privilege escalation.

## Recommended remediation

Add a focused backlog item to handle non-syntax `Psych::Exception` failures in the import path with the same sanitized `ERROR: Could not parse inventory snapshot ...` style, and add regression cases for aliases/disallowed classes.

A later hardening pass may also consider explicit snapshot size/entity/depth limits, but this fuzz pass did not find practical timeout behavior at the bounded sizes tested.
