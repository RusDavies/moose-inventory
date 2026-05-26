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
          operation = Moose::Inventory::Operations::RemoveVariables.new(
            context: Moose::Inventory::InventoryContext.new(db: db),
            entity_type: :group,
            emitter: group_rmvar_emitter(name, vars)
          )

          db.transaction do
            operation.call(name: name, vars: vars)
          end

          puts 'Succeeded.'
        end

        private

        def group_rmvar_emitter(name, vars)
          lambda do |event|
            render_rmvar_event(
              event,
              entity_label: 'group',
              entity_name: name,
              variables_label: vars.join(',')
            )
          end
        end

        def render_rmvar_event(event, entity_label:, entity_name:, variables_label:)
          case event.type
          when :entity_started
            puts "Remove variable(s) '#{variables_label}' from #{entity_label} '#{entity_name}':"
          when :retrieving_entity
            fmt.puts 2, "- retrieve #{entity_label} '#{event.payload[:name]}'..."
          when :removing_variable
            fmt.puts 2, "- remove variable '#{event.payload[:variable]}'..."
          when :entity_complete
            fmt.puts 2, '- all OK'
          when :ok
            fmt.puts event.payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
