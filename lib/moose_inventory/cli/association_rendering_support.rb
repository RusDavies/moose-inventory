# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared string helpers for host/group association commands.
      module AssociationRenderingSupport
        private

        def addition_warning_event?(type)
          %i[
            host_group_association_exists
            group_host_association_exists
            group_missing_created
            host_missing_created
          ].include?(type)
        end

        def removal_warning_event?(type)
          %i[host_group_association_missing group_host_association_missing].include?(type)
        end

        def render_addition_warning(type, payload, perspective:)
          if %i[host_group_association_exists group_host_association_exists].include?(type)
            fmt.warn warning_text(
              "Association #{association_label(payload, perspective:)} already exists, skipping.",
              perspective:
            )
          else
            fmt.warn warning_text(
              "#{missing_entity_label(perspective).capitalize} '#{payload[:name]}' does not exist and will be created.",
              perspective:
            )
          end
        end

        def render_addition_existing(payload, perspective:)
          fmt.puts payload[:indent], "- #{existing_status_text(perspective)}"
        end

        def render_removal_warning(payload, perspective:)
          fmt.warn "Association #{association_label(payload, perspective:)} doesn't exist, skipping.\n"
        end

        def render_removal_missing(payload, perspective:)
          fmt.puts payload[:indent], "- #{missing_status_text(perspective)}"
        end

        def association_label(payload, perspective:)
          if perspective == :host
            "{host:#{payload[:host]} <-> group:#{payload[:group]}}"
          else
            "{group:#{payload[:group]} <-> host:#{payload[:host]}}"
          end
        end

        def automatic_group_label(host, perspective:)
          if perspective == :host
            "{host:#{host} <-> group:ungrouped}"
          else
            "{group:ungrouped <-> host:#{host}}"
          end
        end

        def verb_for(action, perspective)
          return action.to_s.capitalize if perspective == :host

          action.to_s
        end

        def missing_entity_label(perspective)
          perspective == :host ? 'Group' : 'host'
        end

        def existing_status_text(perspective)
          perspective == :host ? 'Already exists, skipping.' : 'already exists, skipping.'
        end

        def missing_status_text(perspective)
          perspective == :host ? "Doesn't exist, skipping." : "doesn't exist, skipping."
        end

        def warning_text(text, perspective:)
          perspective == :host ? text : "#{text}\n"
        end
      end
    end
  end
end
