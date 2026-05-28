# frozen_string_literal: true

require_relative 'operation_event_support'

module Moose
  module Inventory
    module Operations
      ##
      # Adds hosts and their optional group associations.
      #
      # The operation mutates inventory state and returns structured events for
      # the CLI adapter to render. Keeping output out of this class makes the
      # inventory behavior easier to exercise without binding every domain test
      # to progress text.
      class AddHosts
        AUTOMATIC_GROUP = 'ungrouped'
        include OperationEventSupport

        def initialize(context:)
          @context = context
        end

        def call(names:, groups:, dry_run: false)
          events = []
          @dry_run = dry_run

          if dry_run
            names.each do |name|
              add_host(name, groups, events)
            end
            emit(events, :dry_run_summary)
            return operation_result(events: events)
          end

          context.transaction do
            names.each do |name|
              add_host(name, groups, events)
            end
          end
          operation_result(events: events)
        end

        private

        attr_reader :context, :dry_run

        def add_host(name, groups, events)
          emit(events, :host_started, name: name)
          host, groups_dataset = create_or_find_host(name, events)

          groups.each do |group_name|
            add_group_association(host, name, group_name, groups_dataset, events)
          end

          add_automatic_group_if_needed(host, name, groups, groups_dataset, events)
          emit(events, :host_complete)
        end

        def create_or_find_host(name, events)
          emit(events, :creating_host, name: name)
          host = context.find_host(name)
          groups_dataset = nil

          if host.nil?
            host = context.create_host(name) unless dry_run
          else
            emit(events, :host_exists, name: name)
            groups_dataset = host.groups_dataset
          end

          emit(events, :ok, indent: 4)
          [host, groups_dataset]
        end

        def add_group_association(host, host_name, group_name, groups_dataset, events)
          return if group_name.nil? || group_name.empty?

          emit(events, :adding_association, host: host_name, group: group_name)
          group = find_or_create_group(group_name, events)

          if association_exists?(groups_dataset, group_name)
            emit(events, :association_exists, host: host_name, group: group_name)
          elsif !dry_run
            host.add_group(group)
          end

          emit(events, :ok, indent: 4)
        end

        def find_or_create_group(name, events)
          group = context.find_group(name)
          return group unless group.nil?

          emit(events, :group_missing_created, name: name)
          context.create_group(name) unless dry_run
        end

        def add_automatic_group_if_needed(host, host_name, requested_groups, groups_dataset, events)
          return unless automatic_group_needed?(host, requested_groups, groups_dataset)

          emit(events, :adding_automatic_group, host: host_name, group: AUTOMATIC_GROUP)
          host.add_group(automatic_group) unless dry_run
          emit(events, :ok, indent: 4)
        end

        def automatic_group_needed?(host, requested_groups, groups_dataset)
          return requested_groups.empty? && (host.nil? || groups_dataset.nil? || groups_dataset.none?) if dry_run

          groups_dataset = host.groups_dataset
          !groups_dataset.nil? && groups_dataset.none?
        end

        def automatic_group
          context.automatic_group
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end
      end
    end
  end
end
