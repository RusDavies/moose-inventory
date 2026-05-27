# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "group listvars" method of the CLI
      class Group
        #==========================
        desc 'listvar', 'List all variables associated with the group'
        def listvars(*argv)
          if ansible_mode?
            abort_if_wrong_ansible_arg_count(argv, 1)
          else
            abort_if_missing_args(argv, 1, '1 or more')
          end

          names = normalize_names(argv)
          results = inventory_query.list_group_vars(names: names, ansible: ansible_mode?)

          if ansible_mode? && inventory_context.find_group(names.first).nil?
            fmt.warn "The Group #{names.first} does not exist."
          end

          fmt.dump(results, output_format)
        end

        private

        def abort_if_wrong_ansible_arg_count(args, expected)
          return if args.length == expected

          abort("ERROR: Wrong number of arguments for Ansible mode, #{args.length} for #{expected}.")
        end
      end
    end
  end
end
