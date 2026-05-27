# frozen_string_literal: true

require 'thor'
require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/add_associations'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group addhost" method of the CLI
      class Group
        #==========================
        desc 'addhost NAME HOSTNAME',
             'Associate a host HOSTNAME with the group NAME'
        def addhost(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          hosts = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group([name])

          result = add_hosts_to_group(name, hosts)

          if result.warning_count.zero?
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def add_hosts_to_group(name, hosts)
          operation = build_operation(Moose::Inventory::Operations::AddAssociations)

          begin
            db.transaction do
              puts "Associate group '#{name}' with host(s) '#{hosts.join(',')}':"
              group = fetch_existing_group_for_addhost(name)
              result = operation.group_to_hosts(group: group, group_name: name, host_names: hosts)
              render_group_addhost_events(result.events)
              fmt.puts 2, '- all OK'
              return result
            end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e.message}")
          end
        end

        def fetch_existing_group_for_addhost(name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = inventory_context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_group_addhost_events(events)
          events.each { |event| render_group_addhost_event(event) }
        end

        def render_group_addhost_event(event)
          payload = event.payload

          return render_group_addhost_warning(event.type, payload) if group_addhost_warning?(event.type)
          return render_group_addhost_status(payload) if event.type == :already_exists_skipping

          render_group_addhost_output(event.type, payload)
        end

        def group_addhost_warning?(type)
          %i[group_host_association_exists host_missing_created].include?(type)
        end

        def render_group_addhost_warning(type, payload)
          if type == :group_host_association_exists
            fmt.warn "Association {group:#{payload[:group]} <-> host:#{payload[:host]}} already exists, skipping.\n"
          else
            fmt.warn "Host '#{payload[:name]}' does not exist and will be created.\n"
          end
        end

        def render_group_addhost_status(payload)
          fmt.puts payload[:indent], '- already exists, skipping.'
        end

        def render_group_addhost_output(type, payload)
          case type
          when :adding_group_host_association
            fmt.puts 2, "- add association {group:#{payload[:group]} <-> host:#{payload[:host]}}..."
          when :host_creating_now
            fmt.puts 4, '- host does not exist, creating now...'
          when :removing_automatic_group
            fmt.puts 2, "- remove automatic association {group:ungrouped <-> host:#{payload[:host]}}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
