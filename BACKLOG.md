# Moose Inventory Modernization Backlog

Status counts: 2 done / 6 open.

## Open

1. Generate and commit a current `Gemfile.lock` after deciding whether to stop ignoring it.
   - `bundle lock` now resolves successfully with Bundler 2.6.9, but `Gemfile.lock` is currently ignored by `.gitignore`.
2. Run the existing RSpec suite and record failures before changing behavior.
3. Modernize stale runtime dependencies with care, especially `json`, `mysql2`, `pg`, `sequel`, `sqlite3`, and `thor`.
4. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.
5. Provide database client development headers so native DB adapter gems can install.
   - After `ruby-devel` was installed, `bundle install` progressed further but `mysql2` failed because MySQL/MariaDB client development headers/libraries are missing; Fedora package is likely `mariadb-connector-c-devel` or `mysql-devel`.
   - `pg` failed because `pg_config` / `libpq-fe.h` is missing; Fedora package is likely `libpq-devel` or `postgresql-devel`.
6. Remove or replace the stale direct `hitimes ~> 1` development dependency.
   - `hitimes 1.3.1` fails to compile against Ruby 3.4 due an incompatible C extension function signature.
   - It appears to be legacy QA/Guard-era tooling rather than runtime code.

## Done

1. Update Ruby/Bundler dependency constraints so the project can resolve with current Bundler/Ruby.
   - Changed the development dependency from `bundler ~> 1` to `bundler >= 1.17, < 3`.
   - Verified dependency resolution with `bundle lock` under Ruby 3.4.8 / Bundler 2.6.9.
2. Provide Ruby development headers for native gem compilation.
   - Russ installed `ruby-devel`; verified `/usr/include/ruby.h` exists.
   - Full `bundle install` now gets past the Ruby header blocker and exposes the next dependency issues above.
