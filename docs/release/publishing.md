# Publishing to RubyGems

This project has historically been published manually to RubyGems as [`moose-inventory`](https://rubygems.org/gems/moose-inventory).

At the time this document was added:

- The latest published RubyGems version was `1.0.8`.
- The repository version was `1.0.9` in `lib/moose_inventory/version.rb`.
- The repository had CI for checks, but no GitHub Actions publishing workflow.

## Release checklist

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

   If the repository version is already higher than the latest RubyGems version, you can publish it as-is after checks pass. If not, bump `lib/moose_inventory/version.rb` first and commit that change before publishing.

3. Run the local release gate.

   ```bash
   ./scripts/check.sh
   ```

   This runs the spec suite, whitespace checks, executable-permission checks, OSV dependency advisory checks, and gem package sanity checks.

4. Push the release commit and wait for CI to pass.

   ```bash
   git push origin master
   ```

   Do not publish to RubyGems until the GitHub Actions CI run for the pushed commit is green.

5. Build the gem from the exact commit you intend to release.

   ```bash
   rm -rf pkg tmp/pkg tmp/package-sanity
   gem build moose-inventory.gemspec
   ```

   The output should be named like `moose-inventory-1.0.9.gem`.

6. Inspect the built gem metadata if desired.

   ```bash
   gem specification moose-inventory-1.0.9.gem name version executables require_paths files --yaml
   ```

7. Publish to RubyGems.

   ```bash
   gem push moose-inventory-1.0.9.gem
   ```

   If RubyGems auth is not already configured, `gem push` will prompt for credentials or an API key.

8. Verify the published version.

   ```bash
   gem info moose-inventory --remote --all
   gem install moose-inventory -v 1.0.9
   moose-inventory --help
   ```

9. Tag the release after RubyGems confirms it is live.

   ```bash
   git tag -a v1.0.9 -m "Release v1.0.9"
   git push origin v1.0.9
   ```

## Authentication notes

Prefer a scoped RubyGems API key over an old global key:

- Scope it to pushing gems, ideally only `moose-inventory` if RubyGems permits that for the account.
- Store it in `~/.gem/credentials` with file mode `0600` if publishing manually.
- Do not commit RubyGems credentials, `.gem/credentials`, shell history containing tokens, or generated private keys.

Check credential file permissions with:

```bash
ls -l ~/.gem/credentials
chmod 0600 ~/.gem/credentials
```

## Current publishing model

Publishing is manual. There is no automated release workflow in this repository yet.

A future improvement would be to configure RubyGems trusted publishing through GitHub Actions so releases can be published from a tagged, reviewed workflow without long-lived RubyGems API keys on a developer machine.

Suggested future workflow:

1. Add RubyGems trusted publishing for this repository and gem.
2. Add a GitHub Actions workflow triggered by `v*` tags.
3. Have the workflow run `./scripts/check.sh`.
4. Build the gem.
5. Publish via trusted publishing only if the tag version matches `Moose::Inventory::VERSION`.

Until that is implemented, use the manual process above.
