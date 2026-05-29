# frozen_string_literal: true

require 'thor'
require 'json'

require_relative '../inventory_context'
require_relative '../operations/remove_hosts'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host rm" method of the CLI
      class Host
        #==========================
        desc 'rm HOSTNAME_1 [HOSTNAME_2 ...]',
             'Remove hosts HOSTNAME_n from the inventory'
        option :dry_run, type: :boolean
        option :yes, type: :boolean, desc: 'Confirm destructive removal without prompting'
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def rm(*argv)
          abort_if_missing_args(argv, 1, '1 or more')
          validate_machine_plan_request!

          names = normalize_names(argv)
          confirm_destructive_action!("host rm #{names.join(',')}")
          result = remove_hosts_operation.call(names: names, dry_run: options[:dry_run])
          return if machine_plan_output_rendered?(result, command: 'host rm')

          record_audit({ command: 'host rm', action: 'remove', entity_type: 'host',
                         entity_names: names }, result: result, dry_run: options[:dry_run])
          render_remove_hosts_events(result.events)
          print_warning_summary(result)
        end

        private

        def remove_hosts_operation
          build_operation(Moose::Inventory::Operations::RemoveHosts)
        end

        def render_remove_hosts_events(events)
          events.each { |event| render_remove_hosts_event(event) }
        end

        def render_remove_hosts_event(event)
          payload = event.payload

          return render_host_rm_progress(event.type, payload) if host_rm_progress_event?(event.type)
          return render_host_rm_warning(payload) if event.type == :host_missing
          return fmt.puts(payload[:indent], '- No such host, skipping.') if event.type == :missing_skipping
          return fmt.puts(payload[:indent], '- OK') if event.type == :ok

          return fmt.puts 2, '- All OK' if event.type == :host_complete

          puts 'Dry run complete. No changes applied.' if event.type == :dry_run_summary
        end

        def host_rm_progress_event?(type)
          %i[host_started retrieving_host destroying_host].include?(type)
        end

        def render_host_rm_progress(type, payload)
          case type
          when :host_started
            puts "Remove host '#{payload[:name]}':"
          when :retrieving_host
            fmt.puts 2, "- Retrieve host '#{payload[:name]}'..."
          when :destroying_host
            fmt.puts 2, "- Destroy host '#{payload[:name]}'..."
          end
        end

        def render_host_rm_warning(payload)
          fmt.warn "Host '#{payload[:name]}' does not exist, skipping.\n"
        end
      end
    end
  end
end
