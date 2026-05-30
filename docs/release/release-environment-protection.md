# GitHub Release Environment Protection Rules

## Status

Status: **Configured release-process evidence**

This document records the current GitHub `release` environment protection settings used by the Moose Inventory trusted-publishing workflow.

Initial confirmation date: 2026-05-29
Protection configuration date: 2026-05-29
Self-review adjustment date: 2026-05-29
Tag policy correction/verification date: 2026-05-29

Confirmation/configuration commands:

```bash
gh api repos/RusDavies/moose-inventory/environments/release --jq '.'
gh api -X PUT repos/RusDavies/moose-inventory/environments/release --input /tmp/moose-env-release.json
gh api -X POST repos/RusDavies/moose-inventory/environments/release/deployment-branch-policies -f name='v*' -f type='tag'
gh api -X DELETE repos/RusDavies/moose-inventory/environments/release/deployment-branch-policies/50646877
gh api repos/RusDavies/moose-inventory/environments/release/deployment-branch-policies --jq '.'
gh run rerun 26670139178
gh api -X POST repos/RusDavies/moose-inventory/actions/runs/26670139178/pending_deployments --input /tmp/moose-approve-deployment.json
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
| Prevent self-review | Disabled (`prevent_self_review: false`) | Disabled because OpenClaw/automation pushes use Russ's GitHub account. With `RusDavies` as the only required reviewer, self-review prevention could block Russ from approving a release deployment triggered through his own account. |
| Wait timer | `0` / none | No arbitrary delay is configured. Human review is the intended release friction. |
| Deployment branch/tag policy mode | Custom branch policies enabled (`protected_branches: false`, `custom_branch_policies: true`) | The environment uses an explicit allow-list rather than all branches/tags. |
| Custom deployment policy | `v*` with `type: tag` | Aligns environment deployment eligibility with the release workflow's `v*` tag trigger. An earlier `type: branch` policy rejected tag `v2.1`; after explicit human approval, it was replaced with a tag policy and verified by the successful `v2.1` release workflow. |
| Admin bypass | Disabled (`can_admins_bypass: false`) | Admins should not be able to bypass environment protection for this environment through the normal bypass setting. |

## Current trusted-publishing path

The current release path relies on these controls:

1. The release workflow only runs on pushed tags matching `v*`.
2. The GitHub `release` environment requires review by `RusDavies` before the release job can proceed.
3. Self-review prevention is disabled so `RusDavies` can approve deployments triggered by automation authenticated as Russ's GitHub account.
4. Admin bypass is disabled for the `release` environment.
5. The environment has a custom tag deployment policy named `v*`.
6. The release workflow verifies that the tag version matches `Moose::Inventory::VERSION`.
7. The release workflow installs security tools and runs:

   ```bash
   MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
   ```

8. RubyGems trusted publishing/OIDC is scoped to repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`.
9. The package sanity gate verifies the gem payload and executable metadata before publishing.

## Tag-policy verification note

The first `v2.1` workflow attempt proved that a custom deployment policy named `v*` with API `type: branch` does not permit tag deployments. GitHub rejected the run before any workflow steps executed with:

```text
Tag "v2.1" is not allowed to deploy to release due to environment protection rules.
```

After explicit human approval, the branch policy was replaced with a custom deployment policy named `v*` and `type: tag`. The rerun of workflow `26670139178` for tag `v2.1` then entered the required-review gate, was approved by `RusDavies`, completed the full release workflow successfully, and published `moose-inventory` version `2.1` to RubyGems.

## Change-control note

Changing GitHub environment protection settings is repository/release-infrastructure administration. AI agents may document the current state and prepare recommendations, but must not change environment rules without explicit human approval.
