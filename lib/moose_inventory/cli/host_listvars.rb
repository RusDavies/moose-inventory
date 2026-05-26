# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host listvars" method of the CLI
      class Host
        #==========================
        desc 'listvar', 'List all variables associated with the host'
        def listvars(*argv)
          if ansible_mode?
            abort_if_wrong_ansible_arg_count(argv, 1)
          else
            abort_if_missing_args(argv, 1, '1 or more')
          end

          names = normalize_names(argv)
          results = query_inventory.list_host_vars(names: names, ansible: ansible_mode?)

          if ansible_mode? && query_context.find_host(names.first).nil?
            fmt.warn "The host #{names.first} does not exist.\n"
          end

          fmt.dump(results, output_format)
        end

        private

        def abort_if_wrong_ansible_arg_count(args, expected)
          return if args.length == expected

          abort("ERROR: Wrong number of arguments for Ansible mode, #{args.length} for #{expected}.")
        end

        def query_inventory
          Moose::Inventory::Operations::QueryInventory.new(context: query_context)
        end

        def query_context
          Moose::Inventory::InventoryContext.new(db: db)
        end
      end
    end
  end
end
