# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared rendering helpers for child-group relation commands.
      module ChildRelationRendering
        private

        def addchild_emitter
          lambda do |event|
            render_addchild_event(event)
          end
        end

        def rmchild_emitter
          lambda do |event|
            render_rmchild_event(event)
          end
        end

        def render_addchild_event(event)
          payload = event.payload

          return render_addchild_warning(event.type, payload) if addchild_warning?(event.type)
          return render_addchild_existing(payload) if event.type == :already_exists_skipping
          return render_child_relation_dry_run_summary if event.type == :dry_run_summary

          case event.type
          when :adding_child_association
            fmt.puts 2, "- add association {group:#{payload[:parent]} <-> group:#{payload[:child]}}..."
          when :child_group_creating_now
            fmt.puts 4, '- child group does not exist, creating now...'
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end

        def render_child_relation_dry_run_summary
          puts 'Dry run complete. No changes applied.'
        end

        def addchild_warning?(type)
          %i[child_association_exists child_group_missing].include?(type)
        end

        def render_addchild_warning(type, payload)
          if type == :child_association_exists
            fmt.warn "Association {group:#{payload[:parent]} <-> group:#{payload[:child]}} already exists, skipping.\n"
          else
            fmt.warn "Group '#{payload[:name]}' does not exist and will be created.\n"
          end
        end

        def render_addchild_existing(payload)
          fmt.puts payload[:indent], '- already exists, skipping.'
        end

        def render_rmchild_event(event)
          payload = event.payload

          return render_rmchild_warning(payload) if event.type == :child_association_missing
          return render_rmchild_missing(payload) if event.type == :missing_skipping
          return render_rmchild_progress(event.type, payload) if rmchild_progress_event?(event.type)
          return render_child_relation_dry_run_summary if event.type == :dry_run_summary

          render_rmchild_status(event.type, payload)
        end

        def rmchild_progress_event?(type)
          %i[
            removing_child_association
            recursively_delete_orphaned_group
            removing_recursive_child_association
          ].include?(type)
        end

        def render_rmchild_progress(type, payload)
          case type
          when :removing_child_association
            fmt.puts 2, "- remove association {group:#{payload[:parent]} <-> group:#{payload[:child]}}..."
          when :recursively_delete_orphaned_group
            fmt.puts 2, "- Recursively delete orphaned group '#{payload[:name]}'..."
          when :removing_recursive_child_association
            fmt.puts 4, "- Remove association {group:#{payload[:parent]} <-> group:#{payload[:child]}}..."
          end
        end

        def render_rmchild_status(type, payload)
          case type
          when :adding_automatic_group_to_host
            fmt.puts payload[:indent], "- Adding automatic association {group:ungrouped <-> host:#{payload[:host]}}..."
          when :destroying_group
            fmt.puts payload[:indent], "- Destroy group '#{payload[:name]}'..."
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end

        def render_rmchild_warning(payload)
          fmt.warn "Association {group:#{payload[:parent]} <-> group:#{payload[:child]}} does not exist, skipping.\n"
        end

        def render_rmchild_missing(payload)
          fmt.puts payload[:indent], "- doesn't exist, skipping."
        end
      end
    end
  end
end
