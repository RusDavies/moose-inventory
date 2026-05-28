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
        def rmvar(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          operation = build_operation(Moose::Inventory::Operations::RemoveVariables,
                                      entity_type: :host,
                                      emitter: host_rmvar_emitter(name, vars))

          db.transaction do
            operation.call(name: name, vars: vars, dry_run: options[:dry_run])
          end

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
