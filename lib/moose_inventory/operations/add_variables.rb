# frozen_string_literal: true

require_relative 'entity_variable_operation_support'

module Moose
  module Inventory
    module Operations
      # Adds host/group variables and updates existing values when needed.
      class AddVariables
        include EntityVariableOperationSupport

        def call(name:, vars:, dry_run: false)
          @events = []
          @dry_run = dry_run

          emit(:entity_started, name: name)
          emit(:retrieving_entity, name: name)
          entity = find_entity(name)
          raise_missing_entity(name) if entity.nil?

          emit(:ok, indent: 4)

          dataset = entity.public_send("#{entity_type}vars_dataset")
          vars.each do |variable|
            add_variable(entity, dataset, variable)
          end

          emit(:entity_complete)
          emit(:dry_run_summary) if dry_run
          operation_result(events: events)
        ensure
          @events = nil
          @dry_run = nil
        end

        private

        attr_reader :dry_run

        def add_variable(entity, dataset, variable)
          emit(:adding_variable, variable: variable)
          key, value = parse_variable(variable)

          existing = dataset[name: key]
          if existing.nil?
            unless dry_run
              record = context.create_variable(entity_type, name: key, value: value)
              entity.public_send("add_#{entity_type}var", record)
            end
          elsif existing[:value] != value
            emit(:updating_existing_variable)
            unless dry_run
              update = context.find_variable(entity_type, existing[:id])
              update[:value] = value
              update.save
            end
          end

          emit(:ok, indent: 4)
        end

        def parse_variable(variable)
          parts = variable.split('=')
          invalid = variable.start_with?('=') || variable.end_with?('=') || parts.length != 2
          raise_invalid_variable(variable) if invalid

          parts
        end

        def raise_invalid_variable(variable)
          raise context.moose_exception_class,
                "Incorrect format in '{#{variable}}'. Expected 'key=value'."
        end
      end
    end
  end
end
