# frozen_string_literal: true

require_relative 'association_rendering_support'

module Moose
  module Inventory
    module Cli
      # Shared rendering helpers for host/group association commands.
      module AssociationRendering
        include Moose::Inventory::Cli::AssociationRenderingSupport

        private

        def host_group_association_addition_emitter(perspective:)
          lambda do |event|
            render_host_group_association_addition_event(event, perspective:)
          end
        end

        def host_group_association_removal_emitter(perspective:)
          lambda do |event|
            render_host_group_association_removal_event(event, perspective:)
          end
        end

        def render_host_group_association_addition_event(event, perspective:)
          payload = event.payload

          return render_addition_warning(event.type, payload, perspective:) if addition_warning_event?(event.type)
          return render_addition_existing(payload, perspective:) if event.type == :already_exists_skipping

          case event.type
          when :adding_host_group_association, :adding_group_host_association
            fmt.puts 2, "- #{verb_for(:add, perspective)} association #{association_label(payload, perspective:)}..."
          when :group_creating_now, :host_creating_now
            fmt.puts 4, "- #{missing_entity_label(perspective)} does not exist, creating now..."
          when :removing_automatic_group
            label = automatic_group_label(payload[:host], perspective:)
            fmt.puts 2, "- #{verb_for(:remove, perspective)} automatic association #{label}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end

        def render_host_group_association_removal_event(event, perspective:)
          payload = event.payload

          return render_removal_warning(payload, perspective:) if removal_warning_event?(event.type)
          return render_removal_missing(payload, perspective:) if event.type == :missing_skipping

          case event.type
          when :removing_host_group_association, :removing_group_host_association
            fmt.puts 2, "- #{verb_for(:remove, perspective)} association #{association_label(payload, perspective:)}..."
          when :adding_automatic_group
            label = automatic_group_label(payload[:host], perspective:)
            fmt.puts 2, "- #{verb_for(:add, perspective)} automatic association #{label}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
