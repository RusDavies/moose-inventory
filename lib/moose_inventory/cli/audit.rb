# frozen_string_literal: true

require 'json'
require 'thor'

module Moose
  module Inventory
    module Cli
      # Audit log inspection commands.
      class Audit < Thor
        include Moose::Inventory::Cli::Helpers

        desc 'list', 'List recent append-only audit events'
        option :limit, type: :numeric, default: 20
        option :format, type: :string, desc: 'Emit audit events as yaml|json|pjson'
        def list
          events = inventory_context.audit_events(limit: options[:limit]).map { |event| serialize_event(event) }
          if options[:format]
            fmt.dump(events, options[:format].downcase)
          else
            render_human_events(events)
          end
        end

        private

        def serialize_event(event)
          {
            id: event.id,
            created_at: event.created_at,
            actor: event.actor,
            command: event.command,
            action: event.action,
            entity_type: event.entity_type,
            entity_name: event.entity_name,
            details: parse_details(event.details)
          }
        end

        def parse_details(details)
          return nil if details.nil? || details.empty?

          JSON.parse(details)
        rescue JSON::ParserError
          details
        end

        def render_human_events(events)
          if events.empty?
            puts 'No audit events recorded.'
            return
          end

          events.each do |event|
            puts "#{event[:id]} #{event[:created_at]} #{event[:command]} " \
                 "#{event[:entity_type]}=#{event[:entity_name]} action=#{event[:action]}"
          end
        end
      end
    end
  end
end
