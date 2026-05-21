# Moose Inventory Modernization Backlog

Status counts: 4 done / 5 open.

## Open

1. Generate and commit a current `Gemfile.lock` after deciding whether to stop ignoring it.
   - `bundle lock` now resolves successfully with Bundler 2.6.9, but `Gemfile.lock` is currently ignored by `.gitignore`.
2. Run the existing RSpec suite and record failures before changing behavior.
3. Modernize stale runtime dependencies with care, especially `json`, `mysql2`, `pg`, `sequel`, `sqlite3`, and `thor`.
4. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.
5. Update the stale `pg` dependency for Ruby 3.4 compatibility.
   - After removing `hitimes`, `bundle install` reaches `pg 0.21.0` and finds `pg_config` plus `libpq-fe.h`, but fails compiling because old `pg` calls removed Ruby API `rb_tainted_str_new`.
   - This is a dependency age problem now, not a missing-header problem.

## Done

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
   - `bundle install` now finds PostgreSQL headers/config (`pg_config`, `libpq-fe.h`).
   - The next PostgreSQL failure is due to stale `pg 0.21.0` Ruby API usage, not missing system packages.
