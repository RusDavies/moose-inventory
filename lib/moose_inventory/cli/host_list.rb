# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      # Implementation of the "host list" method of the CLI
      class Host
        desc 'list', 'List the contents of the inventory by host'
        def list
          fmt.dump(inventory_query.list_hosts, output_format)
        end
      end
    end
  end
end
