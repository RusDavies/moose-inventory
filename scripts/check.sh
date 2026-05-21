#!/bin/bash
set -euo pipefail

bundle exec rspec --format progress
git diff --check
scripts/ci/check_permissions.sh
scripts/ci/check_security.sh
scripts/ci/package_sanity.sh
