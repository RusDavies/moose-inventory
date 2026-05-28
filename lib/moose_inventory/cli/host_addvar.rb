# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/add_variables'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host addvar" method of the CLI
      class Host
        #==========================
        desc 'addvar', 'Add a variable to the host'
        option :dry_run, type: :boolean
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def addvar(*args)
          abort_if_missing_args(args, 2, '2 or more')
          validate_machine_plan_request!

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          operation = build_operation(Moose::Inventory::Operations::AddVariables,
                                      entity_type: :host,
                                      emitter: machine_plan_emitter(host_addvar_emitter(name, vars)))

          result = db.transaction do
            operation.call(name: name, vars: vars, dry_run: options[:dry_run])
          end

          return if machine_plan_output_rendered?(result, command: 'host addvar')

          record_audit({ command: 'host addvar', action: 'add_variable', entity_type: 'host',
                         entity_names: name }, result: result, dry_run: options[:dry_run])
          print_success_summary
        end

        private

        def host_addvar_emitter(name, vars)
          variable_operation_emitter(
            action: :add,
            entity_label: 'host',
            entity_name: name,
            variables_label: vars.join(',')
          )
        end
      end
    end
  end
end
