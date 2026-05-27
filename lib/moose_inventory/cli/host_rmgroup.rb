# frozen_string_literal: true

require 'thor'
require 'json'

require_relative 'formatter'
require_relative '../db/exceptions'
require_relative '../inventory_context'
require_relative '../operations/remove_associations'

module Moose
  module Inventory
    module Cli
      ##
      # implementation the "host rmgroup" methods of the CLI
      class Host
        #==========================
        desc 'rmgroup HOSTNAME GROUPNAME [GROUPNAME ...]',
             'dissociation the host from a group'
        def rmgroup(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          groups = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group(groups)

          operation = build_operation(Moose::Inventory::Operations::RemoveAssociations)

          db.transaction do
            puts "Dissociate host '#{name}' from groups '#{groups.join(',')}':"
            host = fetch_existing_host_for_rmgroup(name)
            render_host_rmgroup_events(
              operation.host_from_groups(host: host, host_name: name, group_names: groups).events
            )
            fmt.puts 2, '- All OK'
          end
          puts 'Succeeded'
        end

        private

        def fetch_existing_host_for_rmgroup(name)
          fmt.puts 2, "- Retrieve host '#{name}'..."
          host = inventory_context.find_host(name)
          raise db.exceptions[:moose], "The host '#{name}' was not found in the database." if host.nil?

          fmt.puts 4, '- OK'
          host
        end

        def render_host_rmgroup_events(events)
          events.each { |event| render_host_rmgroup_event(event) }
        end

        def render_host_rmgroup_event(event)
          payload = event.payload

          return render_host_rmgroup_warning(payload) if event.type == :host_group_association_missing
          return render_host_rmgroup_missing(payload) if event.type == :missing_skipping

          case event.type
          when :removing_host_group_association
            fmt.puts 2, "- Remove association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
          when :adding_automatic_group
            fmt.puts 2, "- Add automatic association {host:#{payload[:host]} <-> group:ungrouped}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end

        def render_host_rmgroup_warning(payload)
          fmt.warn "Association {host:#{payload[:host]} <-> group:#{payload[:group]}} doesn't exist, skipping.\n"
        end

        def render_host_rmgroup_missing(payload)
          fmt.puts payload[:indent], "- Doesn't exist, skipping."
        end
      end
    end
  end
end
