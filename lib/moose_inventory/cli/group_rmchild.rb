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
          operation = build_operation(Moose::Inventory::Operations::GroupChildRelations)

          begin
            db.transaction do
              puts "Dissociate parent group '#{parent_name}' from child group(s) '#{child_names.join(',')}':"
              parent_group = fetch_existing_group_for_rmchild(parent_name)
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

        def fetch_existing_group_for_rmchild(name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = inventory_context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_rmchild_events(events)
          emitter = rmchild_emitter
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
