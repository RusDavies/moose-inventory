# Publishing to RubyGems

This project is published to RubyGems as [`moose-inventory`](https://rubygems.org/gems/moose-inventory).

The preferred publishing path is GitHub Actions trusted publishing from reviewed `v*` tags. Manual publishing remains documented as a fallback only.

## Trusted publishing setup

The repository side is `.github/workflows/release.yml`.

RubyGems has a trusted publisher configured for the existing `moose-inventory` gem on RubyGems.org with these values:

- Repository owner: `RusDavies`
- Repository name: `moose-inventory`
- Workflow filename: `release.yml`
- Environment: `release`
- Workflow repository owner/name: blank, because the workflow lives in this repository

The release workflow requires the GitHub environment name `release`. If that environment has protection rules, approve the deployment when releasing.

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

3. Run the local release gate.

   ```bash
   ./scripts/check.sh
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
