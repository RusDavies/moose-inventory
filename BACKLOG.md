# Moose Inventory Release Readiness Backlog

Release readiness status counts: 4 done / 3 open.

## Open

1. Resolve GitHub Actions Node.js 20 deprecation warning.
   - Current CI passes, but GitHub warns that `actions/checkout@v4` is running on Node.js 20 and Node.js 24 will become the default.
   - Review available `actions/checkout` updates or GitHub-recommended configuration, then update the workflow so CI stays warning-free before Node.js 20 removal.

1. Add GitHub Actions RubyGems trusted publishing.
   - Manual publishing is documented in `docs/release/publishing.md`.
   - Future improvement: configure RubyGems trusted publishing, publish from reviewed `v*` tags, and avoid long-lived RubyGems API keys on developer machines.

1. Decide and declare the supported Ruby version floor.
   - `gem build` now warns that the gemspec does not set `required_ruby_version`.
   - Pick the oldest Ruby version this maintained branch should support, then add the gemspec constraint and CI matrix coverage for that floor.

## Done

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
