#!/bin/bash
set -euo pipefail

bundle exec rubocop \
  lib/moose_inventory/inventory_context.rb \
  lib/moose_inventory/operations/add_hosts.rb \
  lib/moose_inventory/operations/add_groups.rb \
  lib/moose_inventory/operations/add_associations.rb \
  lib/moose_inventory/operations/remove_associations.rb \
  lib/moose_inventory/operations/group_cleanup.rb \
  lib/moose_inventory/operations/group_child_relations.rb \
  lib/moose_inventory/operations/remove_groups.rb \
  lib/moose_inventory/operations/add_variables.rb \
  lib/moose_inventory/operations/remove_variables.rb \
  lib/moose_inventory/operations/query_inventory.rb \
  lib/moose_inventory/cli/helpers.rb \
  lib/moose_inventory/cli/host_add.rb \
  lib/moose_inventory/cli/group_add.rb \
  lib/moose_inventory/cli/host_addgroup.rb \
  lib/moose_inventory/cli/group_addhost.rb \
  lib/moose_inventory/cli/host_rmgroup.rb \
  lib/moose_inventory/cli/group_rmhost.rb \
  lib/moose_inventory/cli/group_addchild.rb \
  lib/moose_inventory/cli/group_rmchild.rb \
  lib/moose_inventory/cli/group_rm.rb \
  lib/moose_inventory/cli/host_addvar.rb \
  lib/moose_inventory/cli/host_rmvar.rb \
  lib/moose_inventory/cli/group_addvar.rb \
  lib/moose_inventory/cli/group_rmvar.rb \
  lib/moose_inventory/cli/host_get.rb \
  lib/moose_inventory/cli/host_list.rb \
  lib/moose_inventory/cli/host_listvars.rb \
  lib/moose_inventory/cli/group_get.rb \
  lib/moose_inventory/cli/group_list.rb \
  lib/moose_inventory/cli/group_listvars.rb \
  spec/lib/moose_inventory/operations/add_hosts_spec.rb \
  spec/lib/moose_inventory/operations/add_groups_spec.rb \
  spec/lib/moose_inventory/operations/add_associations_spec.rb \
  spec/lib/moose_inventory/operations/remove_associations_spec.rb \
  spec/lib/moose_inventory/operations/group_child_relations_spec.rb \
  spec/lib/moose_inventory/operations/remove_groups_spec.rb \
  spec/lib/moose_inventory/operations/add_variables_spec.rb \
  spec/lib/moose_inventory/operations/remove_variables_spec.rb \
  spec/lib/moose_inventory/operations/query_inventory_spec.rb
