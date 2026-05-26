#!/bin/bash
set -euo pipefail

bundle exec rubocop \
  lib/moose_inventory/inventory_context.rb \
  lib/moose_inventory/operations/add_hosts.rb \
  lib/moose_inventory/operations/add_groups.rb \
  lib/moose_inventory/operations/add_associations.rb \
  lib/moose_inventory/operations/remove_associations.rb \
  lib/moose_inventory/cli/helpers.rb \
  lib/moose_inventory/cli/host_add.rb \
  lib/moose_inventory/cli/group_add.rb \
  lib/moose_inventory/cli/host_addgroup.rb \
  lib/moose_inventory/cli/group_addhost.rb \
  lib/moose_inventory/cli/host_rmgroup.rb \
  lib/moose_inventory/cli/group_rmhost.rb \
  spec/lib/moose_inventory/operations/add_hosts_spec.rb \
  spec/lib/moose_inventory/operations/add_groups_spec.rb \
  spec/lib/moose_inventory/operations/add_associations_spec.rb \
  spec/lib/moose_inventory/operations/remove_associations_spec.rb
