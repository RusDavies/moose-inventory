# frozen_string_literal: true

require_relative 'entity_variable_operation_support'

module Moose
  module Inventory
    module Operations
      # Removes host/group variables by key.
      class RemoveVariables
        include EntityVariableOperationSupport

        def call(name:, vars:)
          @events = []

          emit(:entity_started, name: name)
          emit(:retrieving_entity, name: name)
          entity = find_entity(name)
          raise_missing_entity(name) if entity.nil?

          emit(:ok, indent: 4)

          dataset = entity.public_send("#{entity_type}vars_dataset")
          vars.each do |variable|
            remove_variable(entity, dataset, variable)
          end

          emit(:entity_complete)
          operation_result(events: events)
        ensure
          @events = nil
        end

        private

        def remove_variable(entity, dataset, variable)
          emit(:removing_variable, variable: variable)
          key = parse_variable_name(variable)

          existing = dataset[name: key]
          unless existing.nil?
            entity.public_send("remove_#{entity_type}var", existing)
            existing.destroy
          end

          emit(:ok, indent: 4)
        end

        def parse_variable_name(variable)
          invalid = variable.start_with?('=') || variable.count('=') > 1
          raise_invalid_variable(variable) if invalid

          variable.split('=').first
        end

        def raise_invalid_variable(variable)
          raise context.moose_exception_class,
                "Incorrect format in {#{variable}}. Expected 'key' or 'key=value'."
        end
      end
    end
  end
end
