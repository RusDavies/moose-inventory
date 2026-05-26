# frozen_string_literal: true

require_relative 'group_cleanup'

module Moose
  module Inventory
    module Operations
      # Removes top-level groups and their direct associations.
      class RemoveGroups
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, :warning_count, keyword_init: true)

        def initialize(context:)
          @context = context
          @cleanup = Moose::Inventory::Operations::GroupCleanup.new(
            context: context,
            emitter: method(:emit)
          )
        end

        def call(names:, recursive: false)
          events = []
          warning_count = 0

          names.each do |name|
            warning_count += remove_group(name, events, recursive: recursive)
          end

          Result.new(events: events, warning_count: warning_count)
        end

        private

        attr_reader :cleanup, :context

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
            parent.remove_child(group)
            emit(events, :ok, indent: 4)
          end
        end

        def remove_child_associations(group, name, events, recursive:)
          group.children_dataset.each do |child|
            emit(events, :removing_child_association, group: name, related_group: child.name)
            group.remove_child(child)
            emit(events, :ok, indent: 4)
            cleanup.delete_orphaned_group(child, events) if recursive
          end
        end

        def emit(events, type, payload = {})
          events << Event.new(type: type, payload: payload)
        end
      end
    end
  end
end
