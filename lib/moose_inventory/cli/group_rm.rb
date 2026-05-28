# frozen_string_literal: true

require 'thor'
require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/remove_groups'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of "group rm" methods of the CLI
      class Group
        #==========================
        option :recursive,
               type: :boolean,
               default: false,
               desc: 'Also delete child groups that become orphaned'
        option :dry_run, type: :boolean
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        desc 'rm NAME',
             'Remove a group NAME from the inventory'
        def rm(*argv)
          abort_if_missing_args(argv, 1, '1 or more')
          validate_machine_plan_request!

          names = normalize_names(argv)

          abort_if_automatic_group(
            names,
            "Cannot manually manipulate the automatic group 'ungrouped'\n"
          )

          result = remove_groups(names)
          print_warning_summary(result) unless machine_plan_output_requested?
        end

        private

        def remove_groups(names)
          operation = build_operation(Moose::Inventory::Operations::RemoveGroups)

          db.transaction do
            result = operation.call(names: names, recursive: options[:recursive], dry_run: options[:dry_run])
            machine_plan_output_rendered?(result, command: 'group rm') || render_group_rm_events(result.events)
            return result
          end
        end

        def render_group_rm_events(events)
          events.each { |event| render_group_rm_event(event) }
        end

        def render_group_rm_event(event)
          payload = event.payload

          render_group_rm_warning(payload) if event.type == :group_missing
          return render_group_rm_progress(event.type, payload) if group_rm_progress?(event.type)
          return puts 'Dry run complete. No changes applied.' if event.type == :dry_run_summary

          render_group_rm_status(event.type, payload)
        end

        def group_rm_progress?(type)
          %i[group_started retrieving_group removing_parent_association removing_child_association].include?(type)
        end

        def render_group_rm_warning(payload)
          fmt.warn "Group '#{payload[:name]}' does not exist, skipping.\n"
        end

        def render_group_rm_progress(type, payload)
          case type
          when :group_started
            puts "Remove group '#{payload[:name]}':"
          when :retrieving_group
            fmt.puts 2, "- Retrieve group '#{payload[:name]}'..."
          when :removing_parent_association, :removing_child_association
            fmt.puts 2, "- Remove association {group:#{payload[:group]} <-> group:#{payload[:related_group]}}..."
          end
        end

        def render_group_rm_status(type, payload)
          return render_group_rm_secondary_status(type, payload) if group_rm_secondary_status?(type)

          case type
          when :group_missing
            fmt.puts 4, '- No such group, skipping.'
          when :destroying_group
            fmt.puts payload[:indent], "- Destroy group '#{payload[:name]}'..."
          when :group_complete
            fmt.puts 2, '- All OK'
          end
        end

        def group_rm_secondary_status?(type)
          %i[
            recursively_delete_orphaned_group
            removing_recursive_child_association
            adding_automatic_group_to_host
            ok
          ].include?(type)
        end

        def render_group_rm_secondary_status(type, payload)
          case type
          when :recursively_delete_orphaned_group
            fmt.puts 2, "- Recursively delete orphaned group '#{payload[:name]}'..."
          when :removing_recursive_child_association
            fmt.puts 4, "- Remove association {group:#{payload[:parent]} <-> group:#{payload[:child]}}..."
          when :adding_automatic_group_to_host
            fmt.puts payload[:indent], "- Adding automatic association {group:ungrouped <-> host:#{payload[:host]}}..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end
      end
    end
  end
end
