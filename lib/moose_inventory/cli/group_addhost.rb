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
        option :dry_run, type: :boolean
        def addhost(*args)
          abort_if_missing_args(args, 2, '2 or more')

          name = args[0].downcase
          hosts = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group([name])

          result = add_hosts_to_group(name, hosts)
          print_warning_summary(result)
        end

        private

        def add_hosts_to_group(name, hosts)
          operation = build_operation(Moose::Inventory::Operations::AddAssociations)
          run_group_relation_transaction(heading: "Associate group '#{name}' with host(s) '#{hosts.join(',')}':") do
            group = fetch_existing_group_or_abort(name)
            result = operation.group_to_hosts(group: group, group_name: name, host_names: hosts,
                                              dry_run: options[:dry_run])
            render_group_addhost_events(result.events)
            result
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
