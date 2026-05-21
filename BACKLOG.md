# Moose Inventory Modernization Backlog

Status counts: 9 done / 1 open.

## Open

1. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.

## Done

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
