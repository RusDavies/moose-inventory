# frozen_string_literal: true

require 'thor'
require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/add_groups'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group add" method of the CLI
      class Group
        #==========================
        desc 'add NAME', 'Add a group NAME to the inventory'
        option :hosts
        def add(*argv)
          abort_if_missing_args(argv, 1, '1 or more')

          names = normalize_names(argv)
          hosts = csv_option_names(options[:hosts])

          abort_if_automatic_group(
            names,
            "ERROR: Cannot manually manipulate the automatic group 'ungrouped'\n"
          )

          result = Moose::Inventory::Operations::AddGroups
                   .new(context: Moose::Inventory::InventoryContext.new(db: db))
                   .call(names: names, hosts: hosts)
          render_add_groups_events(result.events)

          if result.warning_count.zero?
            puts 'Succeeded'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def render_add_groups_events(events)
          events.each { |event| render_add_groups_event(event) }
        end

        def render_add_groups_event(event)
          payload = event.payload

          return render_add_groups_event_puts(event.type, payload) if puts_event?(event.type)
          return render_add_groups_event_warn(event.type, payload) if warn_event?(event.type)

          render_add_groups_event_fmt(event.type, payload)
        end

        def puts_event?(type)
          type == :group_started
        end

        def warn_event?(type)
          %i[group_exists host_missing_created association_exists].include?(type)
        end

        def render_add_groups_event_puts(type, payload)
          puts "Add group '#{payload[:name]}':" if type == :group_started
        end

        def render_add_groups_event_warn(type, payload)
          case type
          when :group_exists
            fmt.warn "Group '#{payload[:name]}' already exists, skipping creation.\n"
          when :host_missing_created
            fmt.warn "Host '#{payload[:name]}' doesn't exist, but will be created.\n"
          when :association_exists
            fmt.warn(
              "Association {group:#{payload[:group]} <-> host:#{payload[:host]}} " \
              "already exists, skipping creation.\n"
            )
          end
        end

        def render_add_groups_event_fmt(type, payload)
          return render_add_groups_event_status(type, payload) if status_event?(type)

          case type
          when :creating_group
            fmt.puts 2, '- create group...'
          when :adding_association
            fmt.puts 2, "- add association {group:#{payload[:group]} <-> host:#{payload[:host]}}..."
          when :host_creating_now
            fmt.puts 4, '- host doesn\'t exist, creating now...'
          when :removing_automatic_group
            fmt.puts 2, "- remove automatic association {group:ungrouped <-> host:#{payload[:host]}}..."
          when :group_complete
            fmt.puts 2, '- all OK'
          end
        end

        def status_event?(type)
          %i[already_exists_skipping ok].include?(type)
        end

        def render_add_groups_event_status(type, payload)
          if type == :already_exists_skipping
            fmt.puts payload[:indent], '- already exists, skipping.'
          else
            fmt.puts payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
