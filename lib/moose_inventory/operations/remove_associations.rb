# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Removes host/group associations for existing primary entities.
      class RemoveAssociations
        AUTOMATIC_GROUP = 'ungrouped'
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, :warning_count, keyword_init: true)

        def initialize(context:)
          @context = context
        end

        def host_from_groups(host:, host_name:, group_names:)
          events = []
          warning_count = 0

          group_names.each do |group_name|
            next if group_name.nil? || group_name.empty?

            warning_count += remove_group_from_host(host, host_name, group_name, events)
          end

          add_automatic_group_if_needed(host, host_name, events)

          Result.new(events: events, warning_count: warning_count)
        end

        def group_from_hosts(group:, group_name:, host_names:)
          events = []
          warning_count = 0
          hosts_dataset = group.hosts_dataset

          host_names.each do |host_name|
            next if host_name.nil? || host_name.empty?

            warning_count += remove_host_from_group(group, group_name, host_name, hosts_dataset, events)
          end

          Result.new(events: events, warning_count: warning_count)
        end

        private

        attr_reader :context

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
          host.remove_group(group) unless group.nil?
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
          group.remove_host(host) unless host.nil?
          emit(events, :ok, indent: 4)
          add_automatic_group_if_needed(host, host_name, events)
          0
        end

        def add_automatic_group_if_needed(host, host_name, events)
          return unless host.groups_dataset.none?

          emit(events, :adding_automatic_group, host: host_name)
          host.add_group(context.automatic_group)
          emit(events, :ok, indent: 4)
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end

        def emit(events, type, payload = {})
          events << Event.new(type: type, payload: payload)
        end
      end
    end
  end
end
