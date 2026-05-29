# GitHub Release Environment Protection Rules

## Status

Status: **Confirmed release-process evidence**

This document records the current GitHub `release` environment protection settings used by the Moose Inventory trusted-publishing workflow.

Confirmation date: 2026-05-29

Confirmation method:

```bash
gh api repos/RusDavies/moose-inventory/environments/release --jq '.'
```

Confirmed repository/environment:

- Repository: `RusDavies/moose-inventory`
- Environment: `release`
- Environment URL: `https://github.com/RusDavies/moose-inventory/deployments/activity_log?environments_filter=release`
- Release workflow: `.github/workflows/release.yml`
- Release trigger: pushed `v*` tags
- Release job environment: `release`
- RubyGems trusted publisher environment: `release`

## Confirmed settings

| Setting | Confirmed value | Release-process interpretation |
| --- | --- | --- |
| Required deployment reviewers | None configured | Pushing a matching release tag does not require a GitHub environment approval before the release job can publish. |
| Wait timer | None configured | The release job is not delayed by the environment. |
| Deployment branch/tag policy | None configured | The environment itself does not restrict which branches or tags may deploy. The workflow trigger still limits this release workflow to `v*` tags. |
| Admin bypass | Enabled (`can_admins_bypass: true`) | If protection rules are added later, admins may be able to bypass them unless this setting is changed. |
| Protection rules array | Empty (`[]`) | No environment protection rules are currently enforcing approval, wait, or branch/tag restrictions. |

## Current trusted-publishing path

The current release path relies on these controls:

1. The release workflow only runs on pushed tags matching `v*`.
2. The release workflow verifies that the tag version matches `Moose::Inventory::VERSION`.
3. The release workflow installs security tools and runs:

   ```bash
   MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
   ```

4. RubyGems trusted publishing/OIDC is scoped to repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`.
5. The package sanity gate verifies the gem payload and executable metadata before publishing.

## Current gap

The GitHub `release` environment exists and is wired into the release workflow, but it currently has no environment protection rules. This means the environment name satisfies RubyGems trusted publishing, but it is not currently adding human approval, wait-time, or environment-level branch/tag restriction friction.

This is not evidence of a broken release workflow. It is a release-governance gap to decide explicitly before relying on environment protection as a control.

## Recommended decision

Before the next intentional release, maintainers should decide whether to add GitHub environment protection rules for `release`, such as:

- required deployment reviewers;
- restricting which users/teams can approve release deployments;
- branch/tag deployment restrictions if GitHub supports the desired tag pattern for this environment;
- disabling or limiting admin bypass if the project needs stronger release separation.

Until maintainers make that decision, release documentation should say that the release environment has no configured protection rules and that release approval is handled outside GitHub environment enforcement.

## Change-control note

Changing GitHub environment protection settings is repository/release-infrastructure administration. AI agents may document the current state and prepare recommendations, but must not change environment rules without explicit human approval.
