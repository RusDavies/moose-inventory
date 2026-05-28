# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared rendering helpers for variable add/remove commands.
      module VariableRendering
        private

        def variable_operation_emitter(action:, entity_label:, entity_name:, variables_label:)
          lambda do |event|
            render_variable_event(
              event,
              action: action,
              entity_label: entity_label,
              entity_name: entity_name,
              variables_label: variables_label
            )
          end
        end

        def render_variable_event(event, action:, entity_label:, entity_name:, variables_label:)
          if event.type == :entity_started
            return puts(variable_operation_heading(action:, entity_label:, entity_name:,
                                                   variables_label:))
          end
          return render_variable_change(event, entity_label) if variable_change_event?(event.type)
          return puts 'Dry run complete. No changes applied.' if event.type == :dry_run_summary

          render_variable_status(event)
        end

        def variable_operation_heading(action:, entity_label:, entity_name:, variables_label:)
          return "Add variables '#{variables_label}' to #{entity_label} '#{entity_name}':" if action == :add

          "Remove variable(s) '#{variables_label}' from #{entity_label} '#{entity_name}':"
        end

        def variable_change_event?(type)
          %i[retrieving_entity adding_variable removing_variable updating_existing_variable].include?(type)
        end

        def render_variable_change(event, entity_label)
          case event.type
          when :retrieving_entity
            fmt.puts 2, "- retrieve #{entity_label} '#{event.payload[:name]}'..."
          when :adding_variable
            fmt.puts 2, "- add variable '#{event.payload[:variable]}'..."
          when :removing_variable
            fmt.puts 2, "- remove variable '#{event.payload[:variable]}'..."
          when :updating_existing_variable
            fmt.puts 4, '- already exists, applying as an update...'
          end
        end

        def render_variable_status(event)
          case event.type
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
