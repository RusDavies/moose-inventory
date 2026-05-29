# GitHub Release Environment Protection Rules

## Status

Status: **Configured release-process evidence**

This document records the current GitHub `release` environment protection settings used by the Moose Inventory trusted-publishing workflow.

Initial confirmation date: 2026-05-29
Protection configuration date: 2026-05-29

Confirmation/configuration commands:

```bash
gh api repos/RusDavies/moose-inventory/environments/release --jq '.'
gh api -X PUT repos/RusDavies/moose-inventory/environments/release --input /tmp/moose-env-release.json
gh api -X POST repos/RusDavies/moose-inventory/environments/release/deployment-branch-policies -f name='v*'
gh api repos/RusDavies/moose-inventory/environments/release/deployment-branch-policies --jq '.'
```

Confirmed repository/environment:

- Repository: `RusDavies/moose-inventory`
- Environment: `release`
- Environment URL: `https://github.com/RusDavies/moose-inventory/deployments/activity_log?environments_filter=release`
- Release workflow: `.github/workflows/release.yml`
- Release trigger: pushed `v*` tags
- Release job environment: `release`
- RubyGems trusted publisher environment: `release`

## Configured settings

| Setting | Configured value | Release-process interpretation |
| --- | --- | --- |
| Required deployment reviewers | `RusDavies` | The `release` environment now requires deployment approval by Russ before the release job can proceed. |
| Prevent self-review | Enabled (`prevent_self_review: true`) | The actor triggering the deployment cannot approve their own deployment when GitHub enforces this rule. |
| Wait timer | `0` / none | No arbitrary delay is configured. Human review is the intended release friction. |
| Deployment branch/tag policy mode | Custom branch policies enabled (`protected_branches: false`, `custom_branch_policies: true`) | The environment uses an explicit allow-list rather than all branches/tags. |
| Custom deployment policy | `v*` | Intended to align environment deployment eligibility with the release workflow's `v*` tag trigger. GitHub API reports this policy object with `type: branch`; verify behavior on the next real release tag and adjust if GitHub does not apply it to tag deployments as expected. |
| Admin bypass | Disabled (`can_admins_bypass: false`) | Admins should not be able to bypass environment protection for this environment through the normal bypass setting. |

## Current trusted-publishing path

The current release path relies on these controls:

1. The release workflow only runs on pushed tags matching `v*`.
2. The GitHub `release` environment requires review by `RusDavies` before the release job can proceed.
3. Self-review prevention is enabled for the required-reviewer protection rule.
4. Admin bypass is disabled for the `release` environment.
5. The environment has a custom deployment policy named `v*`.
6. The release workflow verifies that the tag version matches `Moose::Inventory::VERSION`.
7. The release workflow installs security tools and runs:

   ```bash
   MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
   ```

8. RubyGems trusted publishing/OIDC is scoped to repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`.
9. The package sanity gate verifies the gem payload and executable metadata before publishing.

## Residual verification note

GitHub accepted the custom deployment policy name `v*`, but the deployment-branch-policy API response reports the policy object as `type: branch`. The next real release should verify that a pushed `v*` tag can still deploy to the `release` environment after human approval.

If GitHub treats the custom policy as branch-only and blocks tag deployments, maintainers should either adjust the environment policy to the supported tag pattern mechanism or document the limitation and rely on the workflow's `v*` tag trigger plus tag/version check as the tag-control layer.

## Change-control note

Changing GitHub environment protection settings is repository/release-infrastructure administration. AI agents may document the current state and prepare recommendations, but must not change environment rules without explicit human approval.
