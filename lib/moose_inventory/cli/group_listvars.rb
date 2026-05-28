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
          validate_listvars_args(argv)

          names = normalize_names(argv)
          results = inventory_query.list_group_vars(names: names, ansible: ansible_mode?)
          warn_if_missing_ansible_listvars_entity(:group, names.first)

          fmt.dump(results, output_format)
        end
      end
    end
  end
end
