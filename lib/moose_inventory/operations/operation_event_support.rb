# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Shared structured event/result plumbing for inventory operations.
      module OperationEventSupport
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, :warning_count, keyword_init: true)

        private

        def build_event(type, payload = {})
          Event.new(type: type, payload: payload)
        end

        def emit(events, type, payload = {})
          events << build_event(type, payload)
        end

        def operation_result(events:, warning_count: 0)
          Result.new(events: events, warning_count: warning_count)
        end
      end
    end
  end
end
