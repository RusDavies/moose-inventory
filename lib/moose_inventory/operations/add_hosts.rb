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
        AUTOMATIC_GROUP = 'ungrouped'.freeze
        Event = Struct.new(:type, :payload, keyword_init: true)
        Result = Struct.new(:events, keyword_init: true)

        def initialize(context:)
          @context = context
        end

        def call(names:, groups:)
          events = []
          context.transaction do
            names.each do |name|
              add_host(name, groups, events)
            end
          end
          Result.new(events: events)
        end

        private

        attr_reader :context

        def add_host(name, groups, events)
          emit(events, :host_started, name: name)
          host, groups_dataset = create_or_find_host(name, events)

          groups.each do |group_name|
            add_group_association(host, name, group_name, groups_dataset, events)
          end

          add_automatic_group_if_needed(host, name, events)
          emit(events, :host_complete)
        end

        def create_or_find_host(name, events)
          emit(events, :creating_host, name: name)
          host = context.find_host(name)
          groups_dataset = nil

          if host.nil?
            host = context.create_host(name)
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
          else
            host.add_group(group)
          end

          emit(events, :ok, indent: 4)
        end

        def find_or_create_group(name, events)
          group = context.find_group(name)
          return group unless group.nil?

          emit(events, :group_missing_created, name: name)
          context.create_group(name)
        end

        def add_automatic_group_if_needed(host, host_name, events)
          groups_dataset = host.groups_dataset
          return if groups_dataset.nil? || groups_dataset.count != 0

          emit(events, :adding_automatic_group, host: host_name, group: AUTOMATIC_GROUP)
          host.add_group(automatic_group)
          emit(events, :ok, indent: 4)
        end

        def automatic_group
          context.automatic_group
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
