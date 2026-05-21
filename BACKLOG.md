# Moose Inventory Modernization Backlog

Status counts: 0 done / 5 open.

## Open

1. Update Ruby/Bundler dependency constraints so the project can install with current Bundler/Ruby.
   - Baseline blocker: `bundle install --path vendor/bundle` fails because the gemspec requires `bundler ~> 1`, while the host has Bundler 2.6.9.
2. Generate and commit a current `Gemfile.lock` after dependency constraints are modernized.
3. Run the existing RSpec suite and record failures before changing behavior.
4. Modernize stale runtime dependencies with care, especially `json`, `mysql2`, `pg`, `sequel`, `sqlite3`, and `thor`.
5. Review old QA tooling (`rubocop ~> 0`, Guard, Coveralls/SimpleCov setup) and decide what still belongs in the project.

## Done

_None yet._
