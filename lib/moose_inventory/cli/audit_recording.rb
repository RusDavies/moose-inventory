# frozen_string_literal: true

require 'json'

module Moose
  module Inventory
    module Cli
      # Shared append-only audit recording helpers for mutating CLI commands.
      module AuditRecording
        private

        def record_audit(metadata, result:, dry_run: false)
          return if dry_run

          inventory_context.record_audit_event(
            command: metadata.fetch(:command),
            action: metadata.fetch(:action),
            actor: ENV.fetch('USER', nil),
            entity_type: metadata.fetch(:entity_type),
            entity_name: Array(metadata.fetch(:entity_names)).join(','),
            details: audit_details(result)
          )
        end

        def audit_details(result)
          JSON.generate(
            warning_count: result.respond_to?(:warning_count) ? result.warning_count : 0,
            events: audit_events_from_result(result)
          )
        end

        def audit_events_from_result(result)
          return [] unless result.respond_to?(:events)

          result.events.map { |event| { type: event.type, payload: event.payload } }
        end
      end
    end
  end
end
