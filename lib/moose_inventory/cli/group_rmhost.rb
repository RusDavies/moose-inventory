# frozen_string_literal: true

require 'thor'
require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/remove_associations'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group rmhost" method of the CLI
      class Group
        #==========================
        desc 'rmhost GROUPNAME HOSTNAME_1 [HOSTNAME_2 ...]',
             'Dissociate the hosts HOSTNAME_n from the group NAME'
        def rmhost(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          hosts = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group([name])

          result = remove_hosts_from_group(name, hosts)

          if result.warning_count.zero?
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def remove_hosts_from_group(name, hosts)
          operation = build_operation(Moose::Inventory::Operations::RemoveAssociations)

          begin
            db.transaction do
              puts "Dissociate group '#{name}' from host(s) '#{hosts.join(',')}':"
              group = fetch_existing_group_for_rmhost(name)
              result = operation.group_from_hosts(group: group, group_name: name, host_names: hosts)
              render_group_rmhost_events(result.events)
              fmt.puts 2, '- all OK'
              return result
            end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e.message}")
          end
        end

        def fetch_existing_group_for_rmhost(name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = inventory_context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_group_rmhost_events(events)
          emitter = host_group_association_removal_emitter(perspective: :group)
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
