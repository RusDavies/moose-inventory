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
        option :dry_run, type: :boolean
        option :yes, type: :boolean, desc: 'Confirm destructive dissociation without prompting'
        option :plan_format, type: :string, desc: 'Emit dry-run plan events as yaml|json|pjson'
        def rmchild(*argv)
          abort_if_missing_args(argv, 2, '2 or more')
          validate_machine_plan_request!

          pname = argv[0].downcase
          cnames = normalize_names(argv.slice(1, argv.length - 1))

          abort_if_automatic_group([pname] + cnames)
          confirm_destructive_action!("group rmchild #{pname} #{cnames.join(',')}")

          result = remove_children_from_group(pname, cnames)
          return if machine_plan_output_rendered?(result, command: 'group rmchild')

          record_audit({ command: 'group rmchild', action: 'dissociate_child', entity_type: 'group',
                         entity_names: pname }, result: result, dry_run: options[:dry_run])
          print_warning_summary(result)
        end

        private

        def remove_children_from_group(parent_name, child_names)
          operation = build_operation(Moose::Inventory::Operations::GroupChildRelations)
          run_group_relation_transaction(
            heading: "Dissociate parent group '#{parent_name}' from child group(s) '#{child_names.join(',')}':",
            on_error: method(:exception_to_s)
          ) do
            parent_group = fetch_existing_group_or_abort(parent_name)
            result = operation.remove_children(
              parent_group: parent_group,
              parent_name: parent_name,
              child_names: child_names,
              delete_orphans: options[:delete_orphans],
              dry_run: options[:dry_run]
            )
            render_rmchild_events(result.events) unless machine_plan_output_requested?
            result
          end
        end

        def render_rmchild_events(events)
          emitter = rmchild_emitter
          events.each { |event| emitter.call(event) }
        end
      end
    end
  end
end
