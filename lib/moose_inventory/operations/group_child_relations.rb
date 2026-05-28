# frozen_string_literal: true

require_relative 'operation_event_support'

require_relative 'group_cleanup'

module Moose
  module Inventory
    module Operations
      class GroupChildRelations
        include OperationEventSupport

        def initialize(context:)
          @context = context
          @cleanup = Moose::Inventory::Operations::GroupCleanup.new(
            context: context,
            emitter: method(:emit)
          )
        end

        def add_children(parent_group:, parent_name:, child_names:)
          events = []
          warning_count = 0
          children_dataset = parent_group.children_dataset

          child_names.each do |child_name|
            next if child_name.nil? || child_name.empty?

            warning_count += add_child(parent_group, parent_name, child_name, children_dataset, events)
          end

          operation_result(events: events, warning_count: warning_count)
        end

        def remove_children(parent_group:, parent_name:, child_names:, delete_orphans: false)
          events = []
          warning_count = 0
          children_dataset = parent_group.children_dataset

          child_names.each do |child_name|
            next if child_name.nil? || child_name.empty?

            warning_count += remove_child(
              {
                parent_group: parent_group,
                parent_name: parent_name,
                child_name: child_name,
                children_dataset: children_dataset,
                events: events,
                delete_orphans: delete_orphans
              }
            )
          end

          operation_result(events: events, warning_count: warning_count)
        end

        private

        attr_reader :cleanup, :context

        def add_child(parent_group, parent_name, child_name, children_dataset, events)
          emit(events, :adding_child_association, parent: parent_name, child: child_name)

          if association_exists?(children_dataset, child_name)
            emit(events, :child_association_exists, parent: parent_name, child: child_name)
            emit(events, :already_exists_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            return 1
          end

          child_group = context.find_group(child_name)
          warning_count = 0
          if child_group.nil?
            emit(events, :child_group_missing, name: child_name)
            emit(events, :child_group_creating_now, name: child_name)
            child_group = context.create_group(child_name)
            emit(events, :ok, indent: 6)
            warning_count = 1
          end

          parent_group.add_child(child_group)
          emit(events, :ok, indent: 4)
          warning_count
        end

        def remove_child(input)
          emit(
            input[:events],
            :removing_child_association,
            parent: input[:parent_name],
            child: input[:child_name]
          )

          unless association_exists?(input[:children_dataset], input[:child_name])
            emit(input[:events], :child_association_missing, parent: input[:parent_name], child: input[:child_name])
            emit(input[:events], :missing_skipping, indent: 4)
            emit(input[:events], :ok, indent: 4)
            return 1
          end

          child_group = context.find_group(input[:child_name])
          input[:parent_group].remove_child(child_group)
          emit(input[:events], :ok, indent: 4)
          cleanup.delete_orphaned_group(child_group, input[:events]) if input[:delete_orphans]
          0
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end
      end
    end
  end
end
