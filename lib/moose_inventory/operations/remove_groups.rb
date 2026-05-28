# frozen_string_literal: true

require_relative 'operation_event_support'

require_relative 'group_cleanup'

module Moose
  module Inventory
    module Operations
      # Removes top-level groups and their direct associations.
      class RemoveGroups
        include OperationEventSupport

        def initialize(context:)
          @context = context
          @cleanup = Moose::Inventory::Operations::GroupCleanup.new(
            context: context,
            emitter: method(:emit)
          )
        end

        def call(names:, recursive: false, dry_run: false)
          events = []
          warning_count = 0
          @dry_run = dry_run
          cleanup.dry_run = dry_run

          names.each do |name|
            warning_count += remove_group(name, events, recursive: recursive)
          end
          emit(events, :dry_run_summary) if dry_run

          operation_result(events: events, warning_count: warning_count)
        end

        private

        attr_reader :cleanup, :context, :dry_run

        def remove_group(name, events, recursive:)
          emit(events, :group_started, name: name)
          emit(events, :retrieving_group, name: name)
          group = context.find_group(name)

          if group.nil?
            emit(events, :group_missing, name: name)
            emit(events, :ok, indent: 4)
            emit(events, :group_complete)
            return 1
          end

          emit(events, :ok, indent: 4)
          remove_parent_associations(group, name, events)
          remove_child_associations(group, name, events, recursive: recursive)
          cleanup.destroy_group(group, events, indent: 2)
          emit(events, :group_complete)
          0
        end

        def remove_parent_associations(group, name, events)
          group.parents_dataset.each do |parent|
            emit(events, :removing_parent_association, group: name, related_group: parent.name)
            parent.remove_child(group) unless dry_run
            emit(events, :ok, indent: 4)
          end
        end

        def remove_child_associations(group, name, events, recursive:)
          group.children_dataset.each do |child|
            emit(events, :removing_child_association, group: name, related_group: child.name)
            group.remove_child(child) unless dry_run
            emit(events, :ok, indent: 4)
            cleanup.delete_orphaned_group(child, events, ignored_parent: group) if recursive
          end
        end
      end
    end
  end
end
