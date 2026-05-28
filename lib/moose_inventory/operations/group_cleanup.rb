# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      # Recursively cleans up orphaned groups and their dependent relations.
      class GroupCleanup
        include OperationEventSupport

        AUTOMATIC_GROUP = 'ungrouped'

        def initialize(context:, emitter:)
          @context = context
          @emitter = emitter
        end

        def delete_orphaned_group(group, events)
          return if group.name == AUTOMATIC_GROUP
          return unless group.parents_dataset.none?

          emit(events, :recursively_delete_orphaned_group, name: group.name)
          group.children_dataset.each do |child|
            emit(events, :removing_recursive_child_association, parent: group.name, child: child.name)
            group.remove_child(child)
            emit(events, :ok, indent: 6)
            delete_orphaned_group(child, events)
          end
          destroy_group(group, events, indent: 4)
        end

        def destroy_group(group, events, indent:)
          group.hosts_dataset.each do |host|
            next unless host.groups_dataset.one?

            emit(events, :adding_automatic_group_to_host, host: host[:name], indent: indent)
            host.add_group(context.automatic_group)
            emit(events, :ok, indent: indent + 2)
          end

          emit(events, :destroying_group, name: group.name, indent: indent)
          group.remove_all_groupvars
          group.remove_all_hosts
          group.destroy
          emit(events, :ok, indent: indent + 2)
        end

        private

        attr_reader :context, :emitter

        def emit(events, type, payload = {})
          emitter.call(events, type, payload)
        end
      end
    end
  end
end
