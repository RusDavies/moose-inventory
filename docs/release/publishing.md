# Publishing to RubyGems

This project is published to RubyGems as [`moose-inventory`](https://rubygems.org/gems/moose-inventory).

The preferred publishing path is GitHub Actions trusted publishing from reviewed `v*` tags. Manual publishing remains documented as a fallback only.

Routine release-infrastructure stewardship and AI-agent boundaries are documented in `docs/maintenance/package-maintenance-and-agent-boundaries.md`.

## Trusted publishing setup

The repository side is `.github/workflows/release.yml`.

RubyGems has a trusted publisher configured for the existing `moose-inventory` gem on RubyGems.org with these values:

- Repository owner: `RusDavies`
- Repository name: `moose-inventory`
- Workflow filename: `release.yml`
- Environment: `release`
- Workflow repository owner/name: blank, because the workflow lives in this repository

The release workflow requires the GitHub environment name `release`. Current environment protection evidence is documented in `docs/release/release-environment-protection.md`.

As of 2026-05-29, the GitHub `release` environment has required reviewer protection for `RusDavies`, self-review prevention disabled, admin bypass disabled, and a custom deployment policy named `v*` with `type: tag`. Self-review prevention is disabled because OpenClaw/automation pushes use Russ's GitHub account; with `RusDavies` as the only required reviewer, enabling self-review prevention could prevent Russ from approving the deployment. The workflow itself still runs only for pushed `v*` tags and verifies tag/version alignment before publishing. Tag deployment behavior was verified by the successful `v2.1` release workflow after replacing the initial branch-typed `v*` policy with a tag-typed policy.

Package provenance hardening beyond RubyGems trusted publishing is evaluated in `docs/release/package-provenance-hardening.md`. Additional checksums, GitHub artifact attestations, signatures, or SBOM publication are future hardening options, not current release blockers.

## Trusted publishing release checklist

1. Start from a clean `master` branch.

   ```bash
   git checkout master
   git pull --ff-only origin master
   git status --short --branch
   ```

2. Confirm the version to publish.

   ```bash
   ruby -e "require './lib/moose_inventory/version'; puts Moose::Inventory::VERSION"
   gem info moose-inventory --remote --all
   ```

   If the repository version is not higher than the latest RubyGems version, bump `lib/moose_inventory/version.rb` first and commit that change before releasing.

3. Run the local release gate with security tools required, and complete the QA/release templates in `docs/qa/qa-documentation-and-release-gates.md`.

   ```bash
   MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh
   ```

4. Push the release commit and wait for CI to pass.

   ```bash
   git push origin master
   ```

5. Create and push the release tag from the exact commit to publish.

   ```bash
   git tag -a v1.0.10 -m "Release moose-inventory 1.0.10"
   git push origin v1.0.10
   ```

6. Watch the `Release gem` workflow.

   ```bash
   gh run list --workflow release.yml --limit 5
   gh run watch <run-id> --exit-status
   ```

The workflow verifies that the pushed tag version matches `Moose::Inventory::VERSION`, runs `./scripts/check.sh`, builds the gem through `rubygems/release-gem@v1`, and publishes using RubyGems trusted publishing/OIDC. No RubyGems API key should be stored in GitHub secrets for this workflow.

Trusted-publishing verification was completed with release tag `v2.0` / gem version `2.0`. The gem published successfully to RubyGems via OIDC, but the initial workflow finished red because the post-publish `rubygems-await` step timed out waiting for the RubyGems full index even though the gem was already available through the API/install path. The workflow now sets `await-release: false` to avoid that false negative; use the direct verification commands below when you want explicit propagation proof after a release.

## Verify the published version

After the workflow succeeds:

```bash
gem info moose-inventory --remote --all
gem install moose-inventory -v 1.0.10
moose-inventory --help
```

Use the actual released version in place of `1.0.10`.

## Manual fallback

Manual publishing should only be used if trusted publishing is unavailable and a RubyGems owner explicitly chooses to publish from a local machine.

1. Run `./scripts/check.sh`.
2. Build the gem from the exact commit intended for release.

   ```bash
   rm -rf pkg tmp/pkg tmp/package-sanity
   gem build moose-inventory.gemspec
   ```

3. Push the built gem.

   ```bash
   gem push moose-inventory-1.0.10.gem
   ```

Prefer a scoped RubyGems API key over an old global key:

- Scope it to pushing gems, ideally only `moose-inventory` if RubyGems permits that for the account.
- Store it in `~/.gem/credentials` with file mode `0600` if publishing manually.
- Do not commit RubyGems credentials, `.gem/credentials`, shell history containing tokens, or generated private keys.

Check credential file permissions with:

```bash
ls -l ~/.gem/credentials
chmod 0600 ~/.gem/credentials
```
