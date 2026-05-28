# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      # Adds host/group associations for existing primary entities.
      class AddAssociations
        AUTOMATIC_GROUP = 'ungrouped'
        include OperationEventSupport

        def initialize(context:)
          @context = context
        end

        def host_to_groups(host:, host_name:, group_names:)
          events = []
          warning_count = 0

          group_names.each do |group_name|
            next if group_name.nil? || group_name.empty?

            warning_count += add_group_to_host(host, host_name, group_name, events)
          end

          remove_automatic_group_from_host(host, host_name, events)

          operation_result(events: events, warning_count: warning_count)
        end

        def group_to_hosts(group:, group_name:, host_names:)
          events = []
          warning_count = 0
          hosts_dataset = group.hosts_dataset

          host_names.each do |host_name|
            next if host_name.nil? || host_name.empty?

            warning_count += add_host_to_group(
              group,
              group_name,
              host_name,
              hosts_dataset,
              events
            )
          end

          operation_result(events: events, warning_count: warning_count)
        end

        private

        attr_reader :context

        def add_group_to_host(host, host_name, group_name, events)
          warning_count = 0
          groups_dataset = host.groups_dataset

          emit(events, :adding_host_group_association, host: host_name, group: group_name)

          if association_exists?(groups_dataset, group_name)
            emit(events, :host_group_association_exists, host: host_name, group: group_name)
            emit(events, :already_exists_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            return warning_count + 1
          end

          group = context.find_group(group_name)
          if group.nil?
            emit(events, :group_missing_created, name: group_name)
            emit(events, :group_creating_now, name: group_name)
            group = context.create_group(group_name)
            emit(events, :ok, indent: 6)
            warning_count += 1
          end

          host.add_group(group)
          emit(events, :ok, indent: 4)
          warning_count
        end

        def add_host_to_group(group, group_name, host_name, hosts_dataset, events)
          warning_count = 0
          emit(events, :adding_group_host_association, group: group_name, host: host_name)

          if association_exists?(hosts_dataset, host_name)
            emit(events, :group_host_association_exists, group: group_name, host: host_name)
            emit(events, :already_exists_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            return warning_count + 1
          end

          host = context.find_host(host_name)
          if host.nil?
            emit(events, :host_missing_created, name: host_name)
            emit(events, :host_creating_now, name: host_name)
            host = context.create_host(host_name)
            emit(events, :ok, indent: 6)
            warning_count += 1
          end

          group.add_host(host)
          emit(events, :ok, indent: 4)
          remove_automatic_group_from_host(host, host_name, events)
          warning_count
        end

        def remove_automatic_group_from_host(host, host_name, events)
          ungrouped = host.groups_dataset[name: AUTOMATIC_GROUP]
          return if ungrouped.nil?

          emit(events, :removing_automatic_group, host: host_name)
          host.remove_group(ungrouped)
          emit(events, :ok, indent: 4)
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end
      end
    end
  end
end
