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
        ADD_HOST_EVENT_RENDERERS = {
          host_started: :render_add_host_started,
          creating_host: :render_add_host_creation,
          host_exists: :render_add_host_exists_warning,
          ok: :render_add_host_ok,
          adding_association: :render_add_host_association,
          group_missing_created: :render_add_host_missing_group_warning,
          association_exists: :render_add_host_association_exists_warning,
          adding_automatic_group: :render_add_host_automatic_group,
          host_complete: :render_add_host_complete
        }.freeze

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
          print_warning_summary(result, success_message: 'Succeeded', warning_message: 'Succeeded')
        end

        private

        def render_add_hosts_events(events)
          fmt.reset_indent
          events.each { |event| render_add_hosts_event(event) }
        end

        def render_add_hosts_event(event)
          renderer = ADD_HOST_EVENT_RENDERERS[event.type]
          send(renderer, event.payload) unless renderer.nil?
        end

        def render_add_host_started(payload)
          puts "Add host '#{payload[:name]}':"
        end

        def render_add_host_creation(payload)
          fmt.puts 2, "- Creating host '#{payload[:name]}'..."
        end

        def render_add_host_exists_warning(payload)
          fmt.warn "The host '#{payload[:name]}' already exists, skipping creation.\n"
        end

        def render_add_host_ok(payload)
          fmt.puts payload[:indent], '- OK'
        end

        def render_add_host_association(payload)
          fmt.puts 2, "- Adding association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
        end

        def render_add_host_missing_group_warning(payload)
          fmt.warn "The group '#{payload[:name]}' doesn't exist, but will be created.\n"
        end

        def render_add_host_association_exists_warning(payload)
          fmt.warn(
            "Association {host:#{payload[:host]} <-> group:#{payload[:group]}} " \
            "already exists, skipping creation.\n"
          )
        end

        def render_add_host_automatic_group(payload)
          fmt.puts 2, "- Adding automatic association {host:#{payload[:host]} <-> group:#{payload[:group]}}..."
        end

        def render_add_host_complete(_payload)
          fmt.puts 2, '- All OK'
        end
      end
    end
  end
end
