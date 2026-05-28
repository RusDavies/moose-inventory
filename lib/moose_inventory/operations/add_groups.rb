# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      ##
      # Adds groups and their optional host associations.
      class AddGroups
        AUTOMATIC_GROUP = 'ungrouped'
        include OperationEventSupport

        def initialize(context:)
          @context = context
        end

        def call(names:, hosts:)
          events = []
          warning_count = 0

          context.transaction do
            names.each do |name|
              warning_count += add_group(name, hosts, events)
            end
          end

          operation_result(events: events, warning_count: warning_count)
        end

        private

        attr_reader :context

        def add_group(name, hosts, events)
          warning_count = 0
          emit(events, :group_started, name: name)
          group, hosts_dataset, created = create_or_find_group(name, events)
          warning_count += 1 unless created

          hosts.each do |host_name|
            next if host_name.nil? || host_name.empty?

            warning_count += add_host_association(group, name, host_name, hosts_dataset, events)
          end

          emit(events, :group_complete)
          warning_count
        end

        def create_or_find_group(name, events)
          emit(events, :creating_group)
          group = context.find_group(name)

          if group.nil?
            group = context.create_group(name)
            emit(events, :ok, indent: 4)
            [group, nil, true]
          else
            emit(events, :group_exists, name: name)
            emit(events, :already_exists_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            [group, group.hosts_dataset, false]
          end
        end

        def add_host_association(group, group_name, host_name, hosts_dataset, events)
          warning_count = 0
          emit(events, :adding_association, group: group_name, host: host_name)
          host, created = find_or_create_host(host_name, events)
          warning_count += 1 if created == :warned_create

          if association_exists?(hosts_dataset, host_name)
            emit(events, :association_exists, group: group_name, host: host_name)
            emit(events, :already_exists_skipping, indent: 4)
            warning_count += 1
          else
            group.add_host(host)
          end
          emit(events, :ok, indent: 4)

          remove_automatic_group_from_host(host, host_name, events)
          warning_count
        end

        def find_or_create_host(name, events)
          host = context.find_host(name)
          return [host, :existing] unless host.nil?

          emit(events, :host_missing_created, name: name)
          emit(events, :host_creating_now, name: name)
          host = context.create_host(name)
          emit(events, :ok, indent: 6)
          [host, :warned_create]
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
