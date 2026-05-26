# frozen_string_literal: true

require 'thor'

require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/group_child_relations'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group rmchild" methods of the CLI
      class Group
        #==========================
        option :delete_orphans,
               type: :boolean,
               default: false,
               desc: 'Delete child groups that become orphaned'
        desc 'rmchild PARENTGROUP CHILDGROUP_1 [CHILDGROUP_2 ... ]',
             'Dissociate one or more child-groups CHILDGROUP_n from PARENTGROUP'
        def rmchild(*argv)
          abort_if_missing_args(argv, 2, '2 or more')

          pname = argv[0].downcase
          cnames = normalize_names(argv.slice(1, argv.length - 1))

          abort_if_automatic_group([pname] + cnames)

          result = remove_children_from_group(pname, cnames)

          if result.warning_count.zero?
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def remove_children_from_group(parent_name, child_names)
          context = Moose::Inventory::InventoryContext.new(db: db)
          operation = Moose::Inventory::Operations::GroupChildRelations.new(context: context)

          begin
            db.transaction do
              puts "Dissociate parent group '#{parent_name}' from child group(s) '#{child_names.join(',')}':"
              parent_group = fetch_existing_group_for_rmchild(context, parent_name)
              result = operation.remove_children(
                parent_group: parent_group,
                parent_name: parent_name,
                child_names: child_names,
                delete_orphans: options[:delete_orphans]
              )
              render_rmchild_events(result.events)
              fmt.puts 2, '- all OK'
              return result
            end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e}")
          end
        end

        def fetch_existing_group_for_rmchild(context, name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_rmchild_events(events)
          events.each { |event| render_rmchild_event(event) }
        end

        def render_rmchild_event(event)
          payload = event.payload

          return render_rmchild_warning(payload) if event.type == :child_association_missing
          return render_rmchild_missing(payload) if event.type == :missing_skipping
          return render_rmchild_progress(event.type, payload) if rmchild_progress_event?(event.type)

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
