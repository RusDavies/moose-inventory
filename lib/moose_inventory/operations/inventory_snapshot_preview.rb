# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Builds a non-mutating preview/diff for an already-validated inventory snapshot.
      # rubocop:disable Metrics/ClassLength
      class InventorySnapshotPreview
        def initialize(context:)
          @context = context
        end

        def call(snapshot:)
          preview = empty_preview
          preview_existing_entities(snapshot, preview)
          preview_group_payloads(snapshot.fetch('groups'), preview)
          preview_host_payloads(snapshot.fetch('hosts'), preview)
          preview_ignored_existing(snapshot, preview)
          preview
        end

        private

        attr_reader :context

        def empty_preview
          {
            'schema_version' => 'snapshot-import-preview-v1',
            'changes_applied' => false,
            'summary' => {
              'hosts_created' => 0,
              'groups_created' => 0,
              'variables_changed' => 0,
              'associations_added' => 0,
              'unchanged' => 0,
              'ignored_existing_hosts' => 0,
              'ignored_existing_groups' => 0,
              'destructive_changes' => 0
            },
            'creates' => { 'hosts' => [], 'groups' => [] },
            'updates' => { 'host_vars' => [], 'group_vars' => [] },
            'associations' => { 'host_groups' => [], 'group_children' => [], 'tags' => [] },
            'unchanged' => {
              'hosts' => [], 'groups' => [], 'host_vars' => [], 'group_vars' => [], 'associations' => []
            },
            'ignored' => { 'existing_hosts_not_in_snapshot' => [], 'existing_groups_not_in_snapshot' => [] },
            'unsupported_destructive_implications' => []
          }
        end

        def preview_existing_entities(snapshot, preview)
          snapshot.fetch('groups').each_key do |name|
            if context.find_group(name).nil?
              add_create(preview, 'groups', name, 'groups_created')
            else
              add_unchanged(preview, 'groups', name)
            end
          end

          snapshot.fetch('hosts').each_key do |name|
            if context.find_host(name).nil?
              add_create(preview, 'hosts', name, 'hosts_created')
            else
              add_unchanged(preview, 'hosts', name)
            end
          end
        end

        def preview_group_payloads(groups, preview)
          groups.each do |name, payload|
            group = context.find_group(name)
            preview_variables(preview, group, :group, name, payload.fetch('vars', {}))
            preview_tags(preview, group, 'group', name, array_value(payload, 'tags'))
            array_value(payload, 'children').each do |child_name|
              preview_association(preview, group, 'group_children', name, child_name) do |entity|
                entity.children_dataset[name: child_name]
              end
            end
          end
        end

        def preview_host_payloads(hosts, preview)
          hosts.each do |name, payload|
            host = context.find_host(name)
            preview_variables(preview, host, :host, name, payload.fetch('vars', {}))
            preview_tags(preview, host, 'host', name, array_value(payload, 'tags'))
            array_value(payload, 'groups').each do |group_name|
              preview_association(preview, host, 'host_groups', name, group_name) do |entity|
                entity.groups_dataset[name: group_name]
              end
            end
          end
        end

        def preview_variables(preview, entity, type, entity_name, variables)
          variables.each do |name, value|
            existing = entity&.public_send("#{type}vars_dataset")&.[](name: name)
            entry = { 'entity' => entity_name, 'name' => name, 'to' => value.to_s }
            if existing.nil?
              add_update(preview, "#{type}_vars", entry)
            elsif existing.value != value.to_s
              add_update(preview, "#{type}_vars", entry.merge('from' => existing.value))
            else
              add_unchanged(preview, "#{type}_vars", entry)
            end
          end
        end

        def preview_tags(preview, entity, entity_type, entity_name, tags)
          context.normalize_tag_names(tags).each do |tag_name|
            entry = { 'entity_type' => entity_type, 'entity' => entity_name, 'tag' => tag_name }
            if entity.nil? || entity.tags_dataset[name: tag_name].nil?
              add_association(preview, 'tags', entry)
            else
              add_unchanged(preview, 'associations', entry)
            end
          end
        end

        def preview_association(preview, entity, key, source, target)
          entry = { 'source' => source, 'target' => target }
          if entity.nil? || yield(entity).nil?
            add_association(preview, key, entry)
          else
            add_unchanged(preview, 'associations', entry.merge('type' => key))
          end
        end

        def preview_ignored_existing(snapshot, preview)
          snapshot_hosts = snapshot.fetch('hosts').keys
          context.all_hosts.each do |host|
            next if snapshot_hosts.include?(host.name)

            preview['ignored']['existing_hosts_not_in_snapshot'] << host.name
            preview['summary']['ignored_existing_hosts'] += 1
          end

          snapshot_groups = snapshot.fetch('groups').keys
          context.all_groups.each do |group|
            next if snapshot_groups.include?(group.name)

            preview['ignored']['existing_groups_not_in_snapshot'] << group.name
            preview['summary']['ignored_existing_groups'] += 1
          end
        end

        def add_create(preview, key, value, counter)
          preview['creates'][key] << value
          preview['summary'][counter] += 1
        end

        def add_update(preview, key, entry)
          preview['updates'][key] << entry
          preview['summary']['variables_changed'] += 1
        end

        def add_association(preview, key, entry)
          preview['associations'][key] << entry
          preview['summary']['associations_added'] += 1
        end

        def add_unchanged(preview, key, entry)
          preview['unchanged'][key] << entry
          preview['summary']['unchanged'] += 1
        end

        def array_value(payload, key)
          payload.fetch(key, []).map(&:to_s)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
