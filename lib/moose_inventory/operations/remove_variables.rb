# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Removes host/group variables by key.
      class RemoveVariables
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
            remove_variable(entity, dataset, variable)
          end

          emit(:entity_complete)
          Result.new(events: events)
        ensure
          @events = nil
        end

        private

        attr_reader :context, :emitter, :entity_type, :events

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
                "Incorrect format in {#{variable}}. Expected 'key' or 'key=value'."
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
