# frozen_string_literal: true

require 'thor'
require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      # Implementation of the "group list" method of the CLI
      class Group
        desc 'list',
             'List the groups, together with any associated hosts and groupvars'
        def list
          results = inventory_query.list_groups(ansible: ansible_mode?)
          fmt.dump(results, output_format)
        end
      end
    end
  end
end
