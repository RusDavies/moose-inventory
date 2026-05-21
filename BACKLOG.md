# Moose Inventory Modernization Backlog

Status counts: 1 done / 5 open.

## Open

1. Generate and commit a current `Gemfile.lock` after deciding whether to stop ignoring it.
   - `bundle lock` now resolves successfully with Bundler 2.6.9, but `Gemfile.lock` is currently ignored by `.gitignore`.
2. Run the existing RSpec suite and record failures before changing behavior.
3. Modernize stale runtime dependencies with care, especially `json`, `mysql2`, `pg`, `sequel`, `sqlite3`, and `thor`.
4. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.
5. Provide a build environment with Ruby development headers so native gems can install.
   - On this Fedora host, `bundle install` now gets past the Bundler constraint but fails compiling native gems because `/usr/share/include/ruby.h` is missing; likely package: `ruby-devel`.

## Done

1. Update Ruby/Bundler dependency constraints so the project can resolve with current Bundler/Ruby.
   - Changed the development dependency from `bundler ~> 1` to `bundler >= 1.17, < 3`.
   - Verified dependency resolution with `bundle lock` under Ruby 3.4.8 / Bundler 2.6.9.
   - Full `bundle install` still needs Ruby development headers for native gem compilation; tracked separately above.
