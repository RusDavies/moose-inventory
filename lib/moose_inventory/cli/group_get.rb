# frozen_string_literal: true

require 'thor'
require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group get" method of the CLI
      class Group
        desc 'get GROUP_1 [GROUP_2 ...]', 'Get groups GROUP_n from the inventory'
        def get(*argv)
          abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more") if argv.empty?

          names = normalize_names(argv)
          fmt.dump(query_inventory.get_groups(names: names), output_format)
        end

        private

        def query_inventory
          Moose::Inventory::Operations::QueryInventory.new(
            context: inventory_context
          )
        end
      end
    end
  end
end
