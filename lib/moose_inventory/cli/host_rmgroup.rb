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
            result = operation.host_from_groups(host: host, host_name: name, group_names: groups)
            render_host_rmgroup_events(result.events)
            fmt.puts 2, '- All OK'
            print_warning_summary(result, success_message: 'Succeeded', warning_message: 'Succeeded')
          end
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
          emitter = host_group_association_removal_emitter(perspective: :host)
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
