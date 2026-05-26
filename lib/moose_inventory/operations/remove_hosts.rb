# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Removes hosts and returns structured progress/warning events.
      class RemoveHosts
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, :warning_count, keyword_init: true)

        def initialize(context:)
          @context = context
        end

        def call(names:)
          events = []
          warning_count = 0

          context.transaction do
            names.each do |name|
              warning_count += remove_host(name, events)
            end
          end

          Result.new(events: events, warning_count: warning_count)
        end

        private

        attr_reader :context

        def remove_host(name, events)
          emit(events, :host_started, name: name)
          emit(events, :retrieving_host, name: name)
          host = context.find_host(name)

          if host.nil?
            emit(events, :host_missing, name: name)
            emit(events, :missing_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            emit(events, :host_complete)
            return 1
          end

          emit(events, :ok, indent: 4)
          emit(events, :destroying_host, name: name)
          host.remove_all_groups
          host.destroy
          emit(events, :ok, indent: 4)
          emit(events, :host_complete)
          0
        end

        def emit(events, type, payload = {})
          events << Event.new(type: type, payload: payload)
        end
      end
    end
  end
end
