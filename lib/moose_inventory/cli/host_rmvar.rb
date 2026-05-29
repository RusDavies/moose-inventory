# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/remove_variables'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host rmvar" method of the CLI
      class Host
        #==========================
        desc 'rmvar', 'Remove a variable from the host'
        option :dry_run, type: :boolean
        option :yes, type: :boolean, desc: 'Confirm destructive removal without prompting'
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def rmvar(*args)
          abort_if_missing_args(args, 2, '2 or more')
          validate_machine_plan_request!

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          confirm_destructive_action!("host rmvar #{name} #{vars.join(',')}")
          operation = build_operation(Moose::Inventory::Operations::RemoveVariables,
                                      entity_type: :host,
                                      emitter: machine_plan_emitter(host_rmvar_emitter(name, vars)))

          result = db.transaction do
            operation.call(name: name, vars: vars, dry_run: options[:dry_run])
          end

          return if machine_plan_output_rendered?(result, command: 'host rmvar')

          record_audit({ command: 'host rmvar', action: 'remove_variable', entity_type: 'host',
                         entity_names: name }, result: result, dry_run: options[:dry_run])
          print_success_summary
        end

        private

        def host_rmvar_emitter(name, vars)
          variable_operation_emitter(
            action: :remove,
            entity_label: 'host',
            entity_name: name,
            variables_label: vars.join(',')
          )
        end
      end
    end
  end
end
