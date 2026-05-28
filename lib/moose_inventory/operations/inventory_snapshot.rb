# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Builds a canonical, portable representation of the current inventory.
      class InventorySnapshot
        VERSION = 1

        def initialize(context:)
          @context = context
        end

        def export
          {
            'version' => VERSION,
            'hosts' => export_hosts,
            'groups' => export_groups
          }
        end

        private

        attr_reader :context

        def export_hosts
          context.all_hosts.sort_by(&:name).to_h do |host|
            [host.name, host_payload(host)]
          end
        end

        def host_payload(host)
          {
            'groups' => host.groups_dataset.map(:name).sort,
            'tags' => host.tags_dataset.map(:name).sort,
            'vars' => variables_hash(host.hostvars_dataset)
          }
        end

        def export_groups
          context.all_groups.sort_by(&:name).to_h do |group|
            [group.name, group_payload(group)]
          end
        end

        def group_payload(group)
          {
            'children' => group.children_dataset.map(:name).sort,
            'tags' => group.tags_dataset.map(:name).sort,
            'vars' => variables_hash(group.groupvars_dataset)
          }
        end

        def variables_hash(dataset)
          dataset.all.sort_by(&:name).to_h { |entry| [entry.name, entry.value] }
        end
      end
    end
  end
end
