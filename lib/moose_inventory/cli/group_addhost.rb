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
              group = fetch_existing_group_or_abort(name)
              result = operation.group_to_hosts(group: group, group_name: name, host_names: hosts)
              render_group_addhost_events(result.events)
              fmt.puts 2, '- all OK'
              return result
            end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e.message}")
          end
        end

        def render_group_addhost_events(events)
          emitter = host_group_association_addition_emitter(perspective: :group)
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
