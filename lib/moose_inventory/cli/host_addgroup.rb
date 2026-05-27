# frozen_string_literal: true

require 'thor'
require 'json'

require_relative 'formatter'
require_relative '../db/exceptions'
require_relative '../inventory_context'
require_relative '../operations/add_associations'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "addgroup" method of the CLI
      class Host
        desc 'addgroup HOSTNAME GROUPNAME [GROUPNAME ...]',
             'Associate the host with a group'
        def addgroup(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          groups = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group(groups)

          context = inventory_context
          operation = Moose::Inventory::Operations::AddAssociations.new(context: context)

          db.transaction do
            puts "Associate host '#{name}' with groups '#{groups.join(',')}':"
            host = fetch_existing_host_for_addgroup(context, name)
            render_host_addgroup_events(
              operation.host_to_groups(host: host, host_name: name, group_names: groups).events
            )
            fmt.puts 2, '- All OK'
          end

          puts 'Succeeded'
        end

        private

        def fetch_existing_host_for_addgroup(context, name)
          fmt.puts 2, "- Retrieve host '#{name}'..."
          host = context.find_host(name)
          raise db.exceptions[:moose], "The host '#{name}' was not found in the database." if host.nil?

          fmt.puts 4, '- OK'
          host
        end

        def render_host_addgroup_events(events)
          events.each { |event| render_host_addgroup_event(event) }
        end

        def render_host_addgroup_event(event)
          payload = event.payload

          return render_host_addgroup_warning(event.type, payload) if host_addgroup_warning?(event.type)
          return render_host_addgroup_status(payload) if event.type == :already_exists_skipping

          render_host_addgroup_output(event.type, payload)
        end

        def host_addgroup_warning?(type)
          %i[host_group_association_exists group_missing_created].include?(type)
        end

        def render_host_addgroup_warning(type, payload)
          if type == :host_group_association_exists
            fmt.warn "Association {host:#{payload[:host]} <-> group:#{payload[:group]}} already exists, skipping."
          else
            fmt.warn "Group '#{payload[:name]}' does not exist and will be created."
          end
        end

        def render_host_addgroup_status(payload)
          fmt.puts payload[:indent], '- Already exists, skipping.'
        end

        def render_host_addgroup_output(type, payload)
          case type
          when :adding_host_group_association
            fmt.puts 2, "- Add association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
          when :group_creating_now
            fmt.puts 4, '- Group does not exist, creating now...'
          when :removing_automatic_group
            fmt.puts 2, "- Remove automatic association {host:#{payload[:host]} <-> group:ungrouped}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
