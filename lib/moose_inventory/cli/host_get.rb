# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      # Class implementing the "host get" method of the CLI
      class Host
        require_relative 'host_add'

        desc 'get HOST_1 [HOST_2 ...]',
             'Get hosts HOST_n from the inventory'
        def get(*argv)
          abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more") if argv.empty?

          names = normalize_names(argv)
          results = inventory_query.get_hosts(names: names)
          fmt.dump(results, output_format)
        end
      end
    end
  end
end
