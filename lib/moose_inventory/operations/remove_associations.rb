# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      # Removes host/group associations for existing primary entities.
      class RemoveAssociations
        AUTOMATIC_GROUP = 'ungrouped'
        include OperationEventSupport

        def initialize(context:)
          @context = context
        end

        def host_from_groups(host:, host_name:, group_names:, dry_run: false)
          events = []
          warning_count = 0
          @dry_run = dry_run

          group_names.each do |group_name|
            next if group_name.nil? || group_name.empty?

            warning_count += remove_group_from_host(host, host_name, group_name, events)
          end

          add_automatic_group_if_needed(host, host_name, events,
                                        planned_empty: planned_host_groups_empty?(host, group_names))
          emit(events, :dry_run_summary) if dry_run

          operation_result(events: events, warning_count: warning_count)
        end

        def group_from_hosts(group:, group_name:, host_names:, dry_run: false)
          events = []
          warning_count = 0
          @dry_run = dry_run
          hosts_dataset = group.hosts_dataset

          host_names.each do |host_name|
            next if host_name.nil? || host_name.empty?

            warning_count += remove_host_from_group(group, group_name, host_name, hosts_dataset, events)
          end

          emit(events, :dry_run_summary) if dry_run

          operation_result(events: events, warning_count: warning_count)
        end

        private

        attr_reader :context, :dry_run

        def remove_group_from_host(host, host_name, group_name, events)
          groups_dataset = host.groups_dataset
          emit(events, :removing_host_group_association, host: host_name, group: group_name)

          unless association_exists?(groups_dataset, group_name)
            emit(events, :host_group_association_missing, host: host_name, group: group_name)
            emit(events, :missing_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            return 1
          end

          group = context.find_group(group_name)
          host.remove_group(group) unless group.nil? || dry_run
          emit(events, :ok, indent: 4)
          0
        end

        def remove_host_from_group(group, group_name, host_name, hosts_dataset, events)
          emit(events, :removing_group_host_association, group: group_name, host: host_name)

          unless association_exists?(hosts_dataset, host_name)
            emit(events, :group_host_association_missing, group: group_name, host: host_name)
            emit(events, :missing_skipping, indent: 4)
            emit(events, :ok, indent: 4)
            return 1
          end

          host = context.find_host(host_name)
          group.remove_host(host) unless host.nil? || dry_run
          emit(events, :ok, indent: 4)
          add_automatic_group_if_needed(host, host_name, events,
                                        planned_empty: dry_run && !host.nil? && host.groups_dataset.one?)
          0
        end

        def add_automatic_group_if_needed(host, host_name, events, planned_empty: false)
          return if host.nil?
          return unless planned_empty || host.groups_dataset.none?

          emit(events, :adding_automatic_group, host: host_name)
          host.add_group(context.automatic_group) unless dry_run
          emit(events, :ok, indent: 4)
        end

        def planned_host_groups_empty?(host, group_names)
          return false unless dry_run

          remaining = host.groups_dataset.map(&:name) - group_names
          remaining.empty?
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end
      end
    end
  end
end
