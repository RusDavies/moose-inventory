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

          result = add_groups_to_host(name, groups)
          print_warning_summary(result, success_message: 'Succeeded', warning_message: 'Succeeded')
        end

        private

        def add_groups_to_host(name, groups)
          operation = build_operation(Moose::Inventory::Operations::AddAssociations)
          run_host_relation_transaction(heading: "Associate host '#{name}' with groups '#{groups.join(',')}':") do
            host = fetch_existing_host_or_raise(name)
            result = operation.host_to_groups(host: host, host_name: name, group_names: groups)
            render_host_addgroup_events(result.events)
            result
          end
        end

        def render_host_addgroup_events(events)
          emitter = host_group_association_addition_emitter(perspective: :host)
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
