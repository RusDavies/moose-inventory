# frozen_string_literal: true

require_relative 'query_inventory/base_query'
require_relative 'query_inventory/host_queries'
require_relative 'query_inventory/group_queries'

module Moose
  module Inventory
    module Operations
      # Read-only inventory query seam for host/group CLI commands.
      class QueryInventory
        def initialize(context:)
          @host_queries = HostQueries.new(context: context)
          @group_queries = GroupQueries.new(context: context)
        end

        def get_hosts(names:)
          host_queries.get_hosts(names: names)
        end

        def list_hosts
          host_queries.list_hosts
        end

        def list_host_vars(names:, ansible:)
          host_queries.list_host_vars(names: names, ansible: ansible)
        end

        def get_groups(names:)
          group_queries.get_groups(names: names)
        end

        def list_groups(ansible:)
          group_queries.list_groups(ansible: ansible)
        end

        def list_group_vars(names:, ansible:)
          group_queries.list_group_vars(names: names, ansible: ansible)
        end

        private

        attr_reader :group_queries, :host_queries
      end
    end
  end
end
