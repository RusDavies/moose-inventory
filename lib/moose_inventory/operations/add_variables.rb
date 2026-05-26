# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Adds host/group variables and updates existing values when needed.
      class AddVariables
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, keyword_init: true)

        def initialize(context:, entity_type:, emitter: nil)
          @context = context
          @entity_type = entity_type
          @emitter = emitter
        end

        def call(name:, vars:)
          @events = []

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
          Result.new(events: events)
        ensure
          @events = nil
        end

        private

        attr_reader :context, :emitter, :entity_type, :events

        def add_variable(entity, dataset, variable)
          emit(:adding_variable, variable: variable)
          key, value = parse_variable(variable)

          existing = dataset[name: key]
          if existing.nil?
            record = context.create_variable(entity_type, name: key, value: value)
            entity.public_send("add_#{entity_type}var", record)
          elsif existing[:value] != value
            emit(:updating_existing_variable)
            update = context.find_variable(entity_type, existing[:id])
            update[:value] = value
            update.save
          end

          emit(:ok, indent: 4)
        end

        def parse_variable(variable)
          parts = variable.split('=')
          invalid = variable.start_with?('=') || variable.end_with?('=') || parts.length != 2
          raise_invalid_variable(variable) if invalid

          parts
        end

        def find_entity(name)
          case entity_type
          when :host
            context.find_host(name)
          when :group
            context.find_group(name)
          else
            raise ArgumentError, "Unsupported entity type: #{entity_type.inspect}"
          end
        end

        def raise_missing_entity(name)
          label = entity_type == :host ? 'host' : 'group'
          raise context.moose_exception_class, "The #{label} '#{name}' does not exist."
        end

        def raise_invalid_variable(variable)
          raise context.moose_exception_class,
                "Incorrect format in '{#{variable}}'. Expected 'key=value'."
        end

        def emit(type, payload = {})
          event = Event.new(type: type, payload: payload)
          events << event
          emitter&.call(event)
          event
        end
      end
    end
  end
end
