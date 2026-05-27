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
        def addvar(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          operation = build_operation(Moose::Inventory::Operations::AddVariables,
                                      entity_type: :host,
                                      emitter: host_addvar_emitter(name, vars))

          db.transaction do
            operation.call(name: name, vars: vars)
          end

          puts 'Succeeded.'
        end

        private

        def host_addvar_emitter(name, vars)
          lambda do |event|
            render_addvar_event(
              event,
              entity_label: 'host',
              entity_name: name,
              variables_label: vars.join(',')
            )
          end
        end

        def render_addvar_event(event, entity_label:, entity_name:, variables_label:)
          case event.type
          when :entity_started
            puts "Add variables '#{variables_label}' to #{entity_label} '#{entity_name}':"
          when :retrieving_entity
            fmt.puts 2, "- retrieve #{entity_label} '#{event.payload[:name]}'..."
          when :adding_variable
            fmt.puts 2, "- add variable '#{event.payload[:variable]}'..."
          when :updating_existing_variable
            fmt.puts 4, '- already exists, applying as an update...'
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
