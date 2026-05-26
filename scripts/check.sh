#!/bin/bash
set -euo pipefail

bundle exec rspec --format progress
scripts/ci/check_rubocop.sh
git diff --check
scripts/ci/check_permissions.sh
scripts/ci/check_security.sh
scripts/ci/check_secrets.sh
scripts/ci/package_sanity.sh
