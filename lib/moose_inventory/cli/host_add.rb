# frozen_string_literal: true

require 'thor'
require 'json'
require 'indentation'

require_relative 'formatter'
require_relative '../db/exceptions'
require_relative '../inventory_context'
require_relative '../operations/add_hosts'

module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "host" methods of the CLI
      class Host
        #==========================
        desc 'add HOSTNAME_1 [HOSTNAME_2 ...]',
             'Add a hosts HOSTNAME_n to the inventory'
        option :groups
        def add(*argv)
          abort_if_missing_args(argv, 1, '1 or more')

          # Arguments
          names = normalize_names(argv)

          # split(/\W+/) splits on hyphens too, which is not what we want
          # groups = options[:groups].downcase.split(/\W+/).uniq
          groups = csv_option_names(options[:groups])

          # Sanity
          abort_if_automatic_group(groups)

          result = build_operation(Moose::Inventory::Operations::AddHosts)
                   .call(names: names, groups: groups)
          render_add_hosts_events(result.events)
          puts 'Succeeded'
        end

        private

        def render_add_hosts_events(events)
          fmt.reset_indent
          events.each { |event| render_add_hosts_event(event) }
        end

        def render_add_hosts_event(event) # rubocop:disable Metrics/CyclomaticComplexity
          payload = event.payload
          case event.type
          when :host_started
            puts "Add host '#{payload[:name]}':"
          when :creating_host
            fmt.puts 2, "- Creating host '#{payload[:name]}'..."
          when :host_exists
            fmt.warn "The host '#{payload[:name]}' already exists, skipping creation.\n"
          when :ok
            fmt.puts payload[:indent], '- OK'
          when :adding_association
            fmt.puts 2, "- Adding association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
          when :group_missing_created
            fmt.warn "The group '#{payload[:name]}' doesn't exist, but will be created.\n"
          when :association_exists
            fmt.warn(
              "Association {host:#{payload[:host]} <-> group:#{payload[:group]}} " \
              "already exists, skipping creation.\n"
            )
          when :adding_automatic_group
            fmt.puts 2, "- Adding automatic association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
          when :host_complete
            fmt.puts 2, '- All OK'
          end
        end
      end
    end
  end
end
