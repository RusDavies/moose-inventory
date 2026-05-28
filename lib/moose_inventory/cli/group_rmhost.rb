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
        option :dry_run, type: :boolean
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def rmhost(*args)
          abort_if_missing_args(args, 2, '2 or more')
          validate_machine_plan_request!

          name = args[0].downcase
          hosts = normalize_names(args.slice(1, args.length - 1))

          abort_if_automatic_group([name])

          result = remove_hosts_from_group(name, hosts)
          return if machine_plan_output_rendered?(result, command: 'group rmhost')

          record_audit({ command: 'group rmhost', action: 'dissociate', entity_type: 'group',
                         entity_names: name }, result: result, dry_run: options[:dry_run])
          print_warning_summary(result)
        end

        private

        def remove_hosts_from_group(name, hosts)
          operation = build_operation(Moose::Inventory::Operations::RemoveAssociations)
          run_group_relation_transaction(heading: "Dissociate group '#{name}' from host(s) '#{hosts.join(',')}':") do
            group = fetch_existing_group_or_abort(name)
            result = operation.group_from_hosts(group: group, group_name: name, host_names: hosts,
                                                dry_run: options[:dry_run])
            render_group_rmhost_events(result.events) unless machine_plan_output_requested?
            result
          end
        end

        def render_group_rmhost_events(events)
          emitter = host_group_association_removal_emitter(perspective: :group)
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
