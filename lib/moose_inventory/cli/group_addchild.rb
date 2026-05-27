# frozen_string_literal: true

require 'thor'
require_relative 'formatter'
require_relative '../inventory_context'
require_relative '../operations/group_child_relations'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group addchild" methods of the CLI
      class Group < Thor
        #==========================
        desc 'addchild PARENTGROUP CHILDGROUP_1 [CHILDGROUP_2 ... ]',
             'Associate one or more child-groups CHILDGROUP_n with PARENTGROUP'
        def addchild(*argv)
          abort_if_missing_args(argv, 2, '2 or more')

          pname = argv[0].downcase
          cnames = normalize_names(argv.slice(1, argv.length - 1))

          abort_if_automatic_group([pname] + cnames)

          result = add_children_to_group(pname, cnames)

          if result.warning_count.zero?
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def add_children_to_group(parent_name, child_names)
          operation = build_operation(Moose::Inventory::Operations::GroupChildRelations)

          begin
            db.transaction do
              puts "Associate parent group '#{parent_name}' with child group(s) '#{child_names.join(',')}':"
              parent_group = fetch_existing_group_for_child_relation(parent_name)
              result = operation.add_children(
                parent_group: parent_group,
                parent_name: parent_name,
                child_names: child_names
              )
              render_addchild_events(result.events)
              fmt.puts 2, '- all OK'
              return result
            end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e}")
          end
        end

        def fetch_existing_group_for_child_relation(name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = inventory_context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_addchild_events(events)
          emitter = addchild_emitter
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
