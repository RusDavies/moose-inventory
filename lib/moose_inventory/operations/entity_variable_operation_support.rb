# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      module EntityVariableOperationSupport
        def initialize(context:, entity_type:, emitter: nil)
          @context = context
          @entity_type = entity_type
          @emitter = emitter
        end

        private

        attr_reader :context, :emitter, :entity_type, :events

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

        def emit(type, payload = {})
          event = self.class::Event.new(type: type, payload: payload)
          events << event
          emitter&.call(event)
          event
        end
      end
    end
  end
end
