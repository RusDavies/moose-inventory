# frozen_string_literal: true

require 'thor'
require_relative '../inventory_context'
require_relative '../operations/add_variables'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group addvar" method of the CLI
      class Group
        #==========================
        desc 'addvar NAME VARNAME=VALUE',
             'Add a variable VARNAME with value VALUE to the group NAME'
        option :dry_run, type: :boolean
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def addvar(*args)
          abort_if_missing_args(args, 2, '2 or more')
          validate_machine_plan_request!

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          operation = build_operation(Moose::Inventory::Operations::AddVariables,
                                      entity_type: :group,
                                      emitter: machine_plan_emitter(group_addvar_emitter(name, vars)))

          result = db.transaction do
            operation.call(name: name, vars: vars, dry_run: options[:dry_run])
          end

          print_success_summary unless machine_plan_output_rendered?(result, command: 'group addvar')
        end

        private

        def group_addvar_emitter(name, vars)
          variable_operation_emitter(
            action: :add,
            entity_label: 'group',
            entity_name: name,
            variables_label: vars.join(',')
          )
        end
      end
    end
  end
end
