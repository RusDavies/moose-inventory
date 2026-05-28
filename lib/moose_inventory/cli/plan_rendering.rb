# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared machine-readable dry-run plan rendering helpers.
      module PlanRendering
        private

        def machine_plan_output_requested?
          respond_to?(:options) && !options[:plan_format].nil?
        end

        def validate_machine_plan_request!
          abort('ERROR: --plan-format requires --dry-run.') if machine_plan_output_requested? && !options[:dry_run]
        end

        def machine_plan_emitter(emitter)
          machine_plan_output_requested? ? nil : emitter
        end

        def machine_plan_output_rendered?(result, command:)
          return false unless machine_plan_output_requested?

          fmt.dump(
            {
              command: command,
              dry_run: true,
              changes_applied: false,
              events: result.events.map { |event| serialize_plan_event(event) }
            },
            options[:plan_format].downcase
          )
          true
        end

        def serialize_plan_event(event)
          {
            type: event.type.to_s,
            payload: stringify_plan_payload(event.payload)
          }
        end

        def stringify_plan_payload(payload)
          payload.to_h.transform_keys(&:to_s)
        end
      end
    end
  end
end
