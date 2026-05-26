# Moose Inventory Release Readiness Backlog

Release readiness status counts: 14 done / 0 open.

## Open

_No open release-readiness items._

## Done

1. Stop `release.yml` from reporting failure when RubyGems full-index propagation lags after a successful publish.
   - Release tag `v2.0` verified RubyGems trusted publishing end-to-end: RubyGems registered `moose-inventory` `2.0`, remote install worked, and the workflow used OIDC/trusted publishing.
   - `rubygems/release-gem@v1` defaulted `await-release: true`, and its `rubygems-await` post-publish wait timed out on the RubyGems full index even though the gem was already published and installable.
   - Set `await-release: false` in `.github/workflows/release.yml` so future successful publishes do not surface as failed releases because of RubyGems full-index propagation lag.
   - Direct RubyGems verification remains documented in `docs/release/publishing.md`.

1. Align release workflow with required CI security tooling.
   - Security audit rerun found that `.github/workflows/release.yml` ran `./scripts/check.sh` without installing or requiring the dedicated security tools, meaning tag-based releases could skip `gitleaks`/`osv-scanner` enforcement if those tools were absent.
   - Added Go setup with cache disabled, installed pinned security tools through `scripts/ci/install_security_tools.sh`, required `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1` during the release check gate, and added the same native-dependency timeout used by CI.
   - Documented the rerun in `docs/security-audit-2026-05-26-rerun.md`; final trusted-publishing proof remains gated on the next real release tag.

1. Verify RubyGems trusted publishing with the next real release tag.
   - Published `moose-inventory` `2.0` from tag `v2.0` through GitHub Actions trusted publishing/OIDC.
   - Release workflow initially failed because the repo lacked a `rake release` task; fixed by adding `require 'bundler/gem_tasks'` to `Rakefile`, then re-pointed `v2.0` to the corrected commit because the first tag attempt had not published a gem.
   - Verified the published gem directly with `gem info moose-inventory --remote --all`, `gem install moose-inventory -v 2.0 --install-dir tmp/release-smoke --no-document`, and `moose-inventory --config spec/config/config.yml version` returning `Version 2.0`.
   - Remaining workflow false-negative is tracked as a separate open release-readiness item.

1. Add manual GitHub Actions CI trigger and harden CI runner setup.
   - Added `workflow_dispatch` to `.github/workflows/ci.yml` so CI can be manually triggered when push events fail to enqueue during a GitHub Actions incident.
   - Verified both push-triggered CI and manual `workflow_dispatch` CI runs succeeded on `master`.
   - Disabled unused `actions/setup-go` caching for the Go-based security tools so the workflow no longer emits a missing-`go.mod` cache warning.
   - Added a timeout to the native dependency installation step so runner package-manager stalls fail fast instead of hanging the matrix indefinitely.

1. Diagnose missing GitHub Actions runs after security-tooling merge.
   - Confirmed the affected commits were pushed and visible on GitHub, with GitHub PushEvents recorded but no check runs created.
   - Confirmed the workflow was active and visible, and GitHub Actions was degraded during the missing-run window due to platform-side authentication/startup issues.
   - Conclusion: the missing runs were caused by a GitHub Actions incident, not by the repository workflow configuration.

1. Install optional local/CI security audit tools.
   - Added `bundler-audit` as a development dependency and wired it into `scripts/ci/check_security.sh`.
   - Added `scripts/ci/install_security_tools.sh` to install pinned `gitleaks` and `osv-scanner` CLI tools into `tmp/security-tools/bin` when they are not already on `PATH`.
   - Added `scripts/ci/check_secrets.sh` and `.gitleaks.toml` so generated audit, coverage, and package-sanity artifacts stay out of dedicated secret scans.
   - Updated GitHub Actions CI to install the Go-based audit tools and require them during `./scripts/check.sh`; local runs skip missing optional tools unless `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1` is set.

1. Configure RubyGems trusted publisher for the existing gem.
   - Repository-side trusted publishing workflow is present in `.github/workflows/release.yml`.
   - RubyGems trusted publisher is configured for the `moose-inventory` gem with repository `RusDavies/moose-inventory`, workflow `release.yml`, and environment `release`.
   - Evidence: RubyGems trusted publisher page shows GitHub Actions for `RusDavies/moose-inventory`, workflow `release.yml`, environment `release`.

1. Add GitHub Actions RubyGems trusted publishing.
   - Added `.github/workflows/release.yml` triggered by `v*` tags.
   - The workflow verifies the tag matches `Moose::Inventory::VERSION`, runs `./scripts/check.sh`, and publishes with `rubygems/release-gem@v1` using OIDC/trusted publishing.
   - Updated `docs/release/publishing.md` and `docs/release/release-readiness.md` with trusted publishing release instructions and RubyGems setup requirements.

1. Resolve GitHub Actions Node.js 20 deprecation warning.
   - Updated the CI workflow to use `actions/checkout@v5`, which runs on the Node.js 24 runtime.
   - Verified with full `./scripts/check.sh` and a post-merge GitHub Actions run with no Node.js 20 deprecation annotations.

1. Decide and declare the supported Ruby version floor.
   - Set `spec.required_ruby_version` to `>= 3.2` in the gemspec.
   - Updated GitHub Actions CI to test Ruby `3.2`, `3.3`, and `3.4` so the declared floor remains exercised.
   - Updated release-readiness documentation to describe matrix coverage.

1. Document manual RubyGems publishing.
   - Added `docs/release/publishing.md` with the current manual release path: verify version, run `./scripts/check.sh`, push and wait for CI, build the gem, `gem push`, verify RubyGems, then tag the release.
   - Noted that the repo currently has CI but no publishing workflow.
   - Added the trusted-publishing follow-up as an open release-readiness item.

1. Create a release-readiness backlog.
   - Added this release-readiness section to track post-modernization packaging/CI hardening separately from the completed modernization and fresh-pass backlogs.

1. Add CI/security gates to prevent regressions.
   - Added `.github/workflows/ci.yml` for GitHub Actions on `master` pushes and pull requests.
   - Expanded `./scripts/check.sh` to run the RSpec suite, `git diff --check`, executable-permission checks, OSV dependency advisory checks, and package sanity checks.
   - Added `scripts/ci/check_permissions.sh` to keep executable bits limited to intentional entrypoints and scripts.
   - Added `scripts/ci/check_security.sh` to query OSV for locked RubyGems dependency advisories.

1. Do a gem/package sanity pass.
   - Added `scripts/ci/package_sanity.sh` to build the gem, inspect the packaged payload, verify required files, check executable metadata, and smoke-test the CLI version command.
   - Documented the release-readiness gate in `docs/release/release-readiness.md`.

---

# Moose Inventory GitHub Issues Backlog

GitHub issues status counts: 4 done / 0 open.

## Open

_No open GitHub issue items._

## Done

1. [#13 Need to refactor](https://github.com/RusDavies/moose-inventory/issues/13)
   - Added shared `Moose::Inventory::Cli::Helpers` for command argument validation, name normalization, CSV option parsing, automatic `ungrouped` validation, association checks, and automatic group membership maintenance.
   - Refactored representative host/group association commands to use the helper layer while preserving existing CLI output and behavior.
   - Verified with focused CLI specs and full `./scripts/check.sh`.

1. [#12 Allow `group rm` to recursively delete orphaned child groups](https://github.com/RusDavies/moose-inventory/issues/12)
   - Kept default deletion conservative: `group rm NAME` removes only the named group and preserves child groups as root groups.
   - Added explicit `group rm --recursive NAME` to delete descendant groups only when they become orphaned by the removal.
   - Added explicit `group rmchild --delete-orphans PARENT CHILD...` to remove parent-child associations and delete orphaned child subtrees.
   - Preserved groups that still have another parent outside the removed edge/subtree.
   - Preserved host safety by moving hosts whose last group is deleted to `ungrouped`.
   - Added regression coverage for recursive deletion, shared-parent preservation, and host fallback to `ungrouped`.

1. [#4 `--trace` doesn't do what it claims](https://github.com/RusDavies/moose-inventory/issues/4)
   - Reproduced the broken trace path: `--trace` attempted to print `$ERROR_INFO.backtrace` without requiring `English`, causing a secondary `NoMethodError` instead of a clean trace dump.
   - Fixed Moose DB transaction trace handling to emit the actual exception full message/backtrace while preserving concise default errors.
   - Added regression coverage for both trace and non-trace Moose DB transaction errors.
   - Verified with full `./scripts/check.sh`.

1. [#14 Passwords in config files](https://github.com/RusDavies/moose-inventory/issues/14)
   - Added `password_env` support for MySQL and PostgreSQL database configuration while preserving the existing `password` key for compatibility.
   - Added regression coverage for missing password configuration, unset password environment variables, and environment-backed MySQL/PostgreSQL connection passwords.
   - Updated README examples to use `password_env` instead of plaintext sample passwords and added credential-handling guidance.
   - Verified with full `./scripts/check.sh`.

---

# Moose Inventory Fresh Pass Backlog

Fresh pass status counts: 8 done / 0 open.

## Open

_No open fresh-pass items._

## Done

1. Refresh user-facing docs and setup scripts after DB support decisions.
   - Fixed README typos/stale DB support notes and documented the tested support matrix: SQLite live file coverage plus MySQL/PostgreSQL adapter/error-path smoke coverage.
   - Updated `scripts/install_dependencies.sh` for current Fedora package names, removing obsolete `mysql-utilities` and using client development headers for SQLite, MariaDB/MySQL, and PostgreSQL.
   - Verified with full `./scripts/check.sh` and shell syntax check for the install script.

1. Add adapter/error-path smoke tests to the stable QA gate.
   - Expanded DB specs included by `./scripts/check.sh` to cover documented adapter dispatch for SQLite, MySQL, and PostgreSQL.
   - Added missing-key error-path smoke coverage for SQLite, MySQL, and PostgreSQL, alongside existing unsupported-adapter and nested SQLite path coverage.
   - Verified with full `./scripts/check.sh`.

1. Harden YAML config loading.
   - Replaced `YAML.load_file` with `YAML.safe_load_file` using no permitted classes, no permitted symbols, and aliases disabled.
   - Added regression coverage ensuring config loading uses the safe YAML loader while preserving existing config fixture behavior.
   - Verified with full `./scripts/check.sh`.

1. Use recursive directory creation for SQLite database paths.
   - Replaced single-level `Dir.mkdir` with `FileUtils.mkdir_p` in `init_sqlite3`.
   - Added regression coverage for nested SQLite database file paths.
   - Verified with full `./scripts/check.sh`.

1. Fix existing-host group association logic in `host add --groups`.
   - Fixed the association-existence condition so existing hosts can be associated with new groups and true duplicate associations are skipped with the existing warning.
   - Added regression coverage for adding a new group to an existing host and idempotently skipping an existing association.
   - Verified with full `./scripts/check.sh`.

1. Fix or de-scope PostgreSQL support.
   - Implemented `init_postgresql` using the existing `pg` dependency and `Sequel.postgres`.
   - Added regression coverage for PostgreSQL connection option wiring without requiring a live PostgreSQL server.
   - Verified with full `./scripts/check.sh`.

1. Fix MySQL adapter support or remove it from advertised support.
   - Fixed `DB.connect` to dispatch documented `adapter: mysql` instead of misspelled `msqsql`.
   - Updated `init_mysql` to require `mysql2` and use `Sequel.mysql2`, matching the project dependency.
   - Added regression coverage for MySQL adapter dispatch and connection option wiring without requiring a live MySQL server.
   - Verified with full `./scripts/check.sh`.

1. Initialize/use DB exception classes before connection failures.
   - Added DB exception initialization before connection setup so unsupported adapters raise `Moose::Inventory::DB::MooseDBException` instead of masking the intended error with `NoMethodError` on nil `@exceptions`.
   - Added regression coverage for unsupported adapter initialization.
   - Verified with full `./scripts/check.sh`.

---

# Moose Inventory Modernization Backlog

Status counts: 10 done / 0 open.

## Open

_No open modernization items._

## Done

1. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.
   - Removed obsolete RuboCop/Guard/Coveralls tooling after confirming current `rubocop 0.93.1` fails under Ruby 3.4 with missing bundled/default gems and obsolete config entries.
   - Kept SimpleCov as the local coverage gate because the RSpec suite still passes with 95.16% line coverage against a 90% minimum.
   - Added `scripts/check.sh` as the stable local QA entry point for `bundle exec rspec --format progress` and documented it in the README.
   - Updated `scripts/reports.sh` to open the remaining SimpleCov HTML report only.
   - Verified with `bundle lock`, `scripts/check.sh`, and `git diff --check`.

1. Modernize remaining stale runtime dependencies with care, especially `mysql2` and `sqlite3`.
   - `pg` has been moved to a Ruby-3.4-compatible constraint.
   - `json`, `sequel`, and `thor` have been moved to Ruby-3.4-compatible constraints.
   - Tightened `mysql2` from `~> 0` to `>= 0.5.7, < 0.6`; Bundler keeps resolving `mysql2 0.5.7`.
   - Relaxed/modernized `sqlite3` from `~> 1` to `>= 1.7, < 3`; Bundler now resolves `sqlite3 2.9.4`.
   - Verified with `bundle update sqlite3 mysql2 --conservative` and `bundle exec rspec --format documentation`: 242 examples, 0 failures; line coverage 95.16%.

1. Generate and commit a current `Gemfile.lock` after deciding whether to stop ignoring it.
   - Removed `/Gemfile.lock` from `.gitignore`.
   - Generated `Gemfile.lock` with Bundler 2.6.9 under Ruby 3.4.8.
   - Verified the lockfile baseline with `bundle exec rspec --format documentation`.

1. Update Ruby/Bundler dependency constraints so the project can resolve with current Bundler/Ruby.
   - Changed the development dependency from `bundler ~> 1` to `bundler >= 1.17, < 3`.
   - Verified dependency resolution with `bundle lock` under Ruby 3.4.8 / Bundler 2.6.9.
2. Provide Ruby development headers for native gem compilation.
   - Russ installed `ruby-devel`; verified `/usr/include/ruby.h` exists.
   - Full `bundle install` now gets past the Ruby header blocker.
3. Remove the stale direct `hitimes ~> 1` development dependency.
   - Removed `spec.add_development_dependency 'hitimes', '~> 1'` from the gemspec.
   - Removed `rubygem-hitimes` from `scripts/install_dependencies.sh`.
   - `hitimes 1.3.1` failed to compile against Ruby 3.4 and was only referenced as legacy development tooling.
   - Verified `bundle lock --print` no longer includes `hitimes`.
4. Move past missing database client headers.
   - `bundle install` now builds/installs both `mysql2` and `pg` dependencies in this environment.
5. Update the stale `pg` dependency for Ruby 3.4 compatibility.
   - Changed `pg` from `~> 0` to `>= 1.5, < 2`.
   - Verified Bundler resolves `pg 1.6.3` instead of `pg 0.21.0`.
   - Verified `bundle install` completes successfully under Ruby 3.4.8 / Bundler 2.6.9.
6. Run the existing RSpec suite and establish a green modern-Ruby baseline.
   - Initial baseline exposed startup/runtime incompatibilities in old `thor`, `json`, and `sequel` constraints.
   - Updated `json` from `~> 1` to `>= 2.7, < 3`.
   - Updated `thor` from `~> 0` to `>= 1.3, < 2`.
   - Updated `sequel` from `~> 4` to `>= 5.80, < 6`.
   - Verified Bundler resolves `json 2.19.5`, `thor 1.5.0`, and `sequel 5.104.0`.
7. Fix RSpec harness compatibility with the current checkout/test flow.
   - `spec_helper` now creates `tmp/` before deleting test database files, avoiding `Errno::ENOENT` on fresh clones.
   - Config specs now pass an explicit fixture config when testing default option values.
   - Ansible-mode CLI specs now pass the fixture config when invoking the top-level CLI.
   - Updated the `--list` expectation for Ansible mode, which correctly includes empty `hosts` arrays.
   - Verified `bundle exec rspec --format documentation`: 242 examples, 0 failures; line coverage 95.16%.

---

# Moose Inventory Code Quality Backlog

Code quality status counts: 10 done / 0 open.

## Open

_No open code quality items._


## Done

1. Extract `group rm` to reuse the new group-cleanup / relation-operation seam.
   - Added `Moose::Inventory::Operations::RemoveGroups` and reused `GroupCleanup` so top-level group deletion, recursive orphan cleanup, and host `ungrouped` reattachment now run through structured operation events instead of bespoke Thor logic.
   - Converted `group rm` into a thinner adapter over `InventoryContext`, preserving `--recursive` behavior and existing CLI output.
   - Added direct operation specs and expanded the targeted RuboCop gate to cover the new removal operation and adapter.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Extract the shared group-parent/child association flow behind `group addchild` and `group rmchild`.
   - Added `Moose::Inventory::Operations::GroupChildRelations` and `GroupCleanup` to own parent/child link creation, dissociation, and recursive orphan-group cleanup with structured events.
   - Converted `group addchild` and `group rmchild` into thinner adapters over `InventoryContext`, including `--delete-orphans` behavior without leaving the recursion logic buried in the CLI layer.
   - Added direct operation specs and expanded the targeted RuboCop gate to cover the new parent/child relation seam.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Extract the shared host/group dissociation flow behind `host rmgroup` and `group rmhost`.
   - Added `Moose::Inventory::Operations::RemoveAssociations` to own shared dissociation, missing-association handling, and automatic `ungrouped` reattachment behavior for existing primary entities.
   - Converted `host rmgroup` and `group rmhost` into thinner adapters that retrieve the primary entity, delegate through `InventoryContext`, and render structured operation events.
   - Added direct operation specs and expanded the targeted RuboCop gate to cover the new removal operation plus both adapter commands.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Extract the shared host/group association flow behind `host addgroup` and `group addhost`.
   - Added `Moose::Inventory::Operations::AddAssociations` to own the shared association, auto-create, duplicate-check, and `ungrouped` removal behavior for existing primary entities.
   - Converted `host addgroup` and `group addhost` into thinner adapters that retrieve the primary entity, delegate through `InventoryContext`, and render structured operation events.
   - Added direct operation specs and expanded the targeted RuboCop gate to cover the new operation plus both adapter commands.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Extract `group add` into the operation/context/event pattern.
   - Added `Moose::Inventory::Operations::AddGroups` with structured result/events and warning counts, mirroring the `host add` refactor pattern.
   - Converted `group add` into a thin Thor adapter that validates input, delegates through `InventoryContext`, and renders operation events without changing CLI behavior.
   - Added direct operation specs and extended the targeted RuboCop scope to cover the new operation/adapter/spec files.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Reintroduce a small modern lint/complexity gate.
   - Added RuboCop as a development dependency and a targeted `.rubocop.yml` for the newly refactored seam instead of the whole legacy tree.
   - Added `scripts/ci/check_rubocop.sh` and wired it into `./scripts/check.sh` so lint/complexity checks run in the standard local and CI gate.
   - Kept the initial lint scope focused on the context/operation/helper/adapter files and direct operation spec, with thresholds strict enough to catch drift without forcing a repo-wide cleanup right now.

1. Separate first structured operation result from CLI rendering.
   - Changed `Moose::Inventory::Operations::AddHosts` to return structured `Result`/`Event` objects instead of writing directly to stdout/stderr.
   - Moved `host add` progress/warning rendering into the Thor adapter while preserving existing user-visible CLI output.
   - Added direct operation specs proving inventory mutation and event emission without renderer output.
   - Verified with focused specs and full `./scripts/check.sh`.

1. Introduce an inventory context facade around DB access.
   - Added `Moose::Inventory::InventoryContext` as a thin wrapper over the existing DB singleton for transaction/model operations.
   - Wired the `AddHosts` operation through the context, reducing direct DB coupling in the first extracted operation while leaving legacy CLI commands stable.
   - Verified with focused `host add` specs and full `./scripts/check.sh`.

1. Extract first domain operation behind a Thor command.
   - Added `Moose::Inventory::Operations::AddHosts` as the first operation/service object behind the CLI.
   - Converted `host add` into a thin adapter that validates/normalizes CLI input and delegates inventory mutation to the operation.
   - Preserved existing `host add` output and behavior under focused specs and full `./scripts/check.sh`.

1. Extract shared CLI helpers for low-risk issue #13 refactor.
   - Added helper methods for common validation, normalization, association checks, and automatic `ungrouped` membership handling.
   - Refactored selected host/group CLI commands without changing user-visible output.
