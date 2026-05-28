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
        option :group, type: :string, desc: 'Only include hosts in all comma-separated groups'
        option :tag, type: :string, desc: 'Only include hosts with all comma-separated tags'
        option :var, type: :string, desc: 'Only include hosts with comma-separated key=value variables'
        def list
          fmt.dump(inventory_query.list_hosts(filters: host_list_filters), output_format)
        end

        private

        def host_list_filters
          {
            groups: csv_option_names(options[:group]),
            tags: csv_option_names(options[:tag]),
            variables: variable_filter_options(options[:var])
          }
        end

        def variable_filter_options(value)
          csv_option_names(value).to_h do |entry|
            key, variable_value = entry.split('=', 2)
            abort("ERROR: Invalid variable filter '#{entry}'. Expected key=value.") if variable_value.nil?

            [key, variable_value]
          end
        end
      end
    end
  end
end
