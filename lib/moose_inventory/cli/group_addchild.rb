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
          context = inventory_context
          operation = Moose::Inventory::Operations::GroupChildRelations.new(context: context)

          begin
            db.transaction do
              puts "Associate parent group '#{parent_name}' with child group(s) '#{child_names.join(',')}':"
              parent_group = fetch_existing_group_for_child_relation(context, parent_name)
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

        def fetch_existing_group_for_child_relation(context, name)
          fmt.puts 2, "- retrieve group '#{name}'..."
          group = context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK'
          group
        end

        def render_addchild_events(events)
          events.each { |event| render_addchild_event(event) }
        end

        def render_addchild_event(event)
          payload = event.payload

          return render_addchild_warning(event.type, payload) if addchild_warning?(event.type)
          return render_addchild_existing(payload) if event.type == :already_exists_skipping

          case event.type
          when :adding_child_association
            fmt.puts 2, "- add association {group:#{payload[:parent]} <-> group:#{payload[:child]}}..."
          when :child_group_creating_now
            fmt.puts 4, '- child group does not exist, creating now...'
          when :ok
            fmt.puts payload[:indent], '- OK'
          end
        end

        def addchild_warning?(type)
          %i[child_association_exists child_group_missing].include?(type)
        end

        def render_addchild_warning(type, payload)
          if type == :child_association_exists
            fmt.warn "Association {group:#{payload[:parent]} <-> group:#{payload[:child]}}} already exists, skipping.\n"
          else
            fmt.warn "Group '#{payload[:name]}' does not exist and will be created.\n"
          end
        end

        def render_addchild_existing(payload)
          fmt.puts payload[:indent], '- already exists, skipping.'
        end
      end
    end
  end
end
