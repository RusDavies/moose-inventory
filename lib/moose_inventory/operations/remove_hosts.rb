# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      # Removes hosts and returns structured progress/warning events.
      class RemoveHosts
        include OperationEventSupport

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

          operation_result(events: events, warning_count: warning_count)
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
      end
    end
  end
end
