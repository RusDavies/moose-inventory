# Moose Inventory Fresh Pass Backlog

Fresh pass status counts: 4 done / 4 open.

## Open

1. Use recursive directory creation for SQLite database paths.
   - Evidence: `init_sqlite3` uses `Dir.mkdir(dbdir)`, which fails when the configured DB file is inside nested missing directories.
   - Replace with `FileUtils.mkdir_p(dbdir)` and add coverage for nested SQLite paths.
2. Harden YAML config loading.
   - Evidence: config loading uses `YAML.load_file`; switch to `YAML.safe_load_file` or equivalent with explicit permitted classes, then verify current config examples still work.
3. Add adapter/error-path smoke tests to the stable QA gate.
   - Cover unsupported adapters, missing config keys, nested SQLite paths, MySQL dispatch behavior, and PostgreSQL behavior/de-scope.
   - This should prevent the currently documented DB modes from rotting silently while the SQLite happy path stays green.
4. Refresh user-facing docs and setup scripts after DB support decisions.
   - Evidence: README has stale typos and claims (`postresql`, `postresql-devel`, line-wrapped `native`), `scripts/install_dependencies.sh` references old Fedora package names such as `mysql-utilities`, and docs still advertise DB adapters that are not green.
   - Update README, install script, and examples to match the support matrix established above.

## Done

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
