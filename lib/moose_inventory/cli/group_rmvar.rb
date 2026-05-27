# frozen_string_literal: true

require 'thor'
require_relative '../inventory_context'
require_relative '../operations/remove_variables'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group rmvar" method of the CLI
      class Group
        #==========================
        desc 'rmvar NAME VARNAME',
             'Remove a variable VARNAME from the group NAME'
        def rmvar(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          operation = build_operation(Moose::Inventory::Operations::RemoveVariables,
                                      entity_type: :group,
                                      emitter: group_rmvar_emitter(name, vars))

          db.transaction do
            operation.call(name: name, vars: vars)
          end

          print_success_summary
        end

        private

        def group_rmvar_emitter(name, vars)
          variable_operation_emitter(
            action: :remove,
            entity_label: 'group',
            entity_name: name,
            variables_label: vars.join(',')
          )
        end
      end
    end
  end
end
