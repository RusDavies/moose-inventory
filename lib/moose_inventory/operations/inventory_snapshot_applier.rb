# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Applies an already-validated inventory snapshot to the current inventory.
      class InventorySnapshotApplier
        Result = Struct.new(:created_hosts, :created_groups, :updated_variables, :associations, keyword_init: true)

        def initialize(context:)
          @context = context
        end

        def call(snapshot:)
          apply_snapshot(snapshot)
        end

        private

        attr_reader :context

        def apply_snapshot(snapshot)
          result = Result.new(created_hosts: 0, created_groups: 0, updated_variables: 0, associations: 0)

          snapshot['groups'].each_key { |name| result.created_groups += 1 if ensure_group(name).nil? }
          snapshot['hosts'].each_key { |name| result.created_hosts += 1 if ensure_host(name).nil? }
          apply_group_payloads(snapshot['groups'], result)
          apply_host_payloads(snapshot['hosts'], result)
          result
        end

        def apply_group_payloads(groups, result)
          groups.each do |name, payload|
            group = context.find_group(name)
            result.updated_variables += apply_variables(group, :group, payload.fetch('vars', {}))
            apply_tags(group, array_value(payload, 'tags'), result)
            array_value(payload, 'children').each do |child_name|
              child = context.find_group(child_name)
              next unless group.children_dataset[name: child_name].nil?

              group.add_child(child)
              result.associations += 1
            end
          end
        end

        def apply_host_payloads(hosts, result)
          hosts.each do |name, payload|
            host = context.find_host(name)
            result.updated_variables += apply_variables(host, :host, payload.fetch('vars', {}))
            apply_tags(host, array_value(payload, 'tags'), result)
            array_value(payload, 'groups').each do |group_name|
              group = context.find_group(group_name)
              next unless host.groups_dataset[name: group_name].nil?

              host.add_group(group)
              result.associations += 1
            end
          end
        end

        def apply_tags(entity, tags, result)
          context.normalize_tag_names(tags).each do |tag_name|
            tag = context.find_or_create_tag(tag_name)
            next unless entity.tags_dataset[name: tag_name].nil?

            entity.add_tag(tag)
            result.associations += 1
          end
        end

        def apply_variables(entity, type, variables)
          variables.count do |name, value|
            dataset = entity.public_send("#{type}vars_dataset")
            existing = dataset[name: name]
            if existing.nil?
              record = context.create_variable(type, name: name, value: value.to_s)
              entity.public_send("add_#{type}var", record)
              true
            elsif existing.value != value.to_s
              existing.value = value.to_s
              existing.save
              true
            else
              false
            end
          end
        end

        def ensure_group(name)
          existing = context.find_group(name)
          return existing unless existing.nil?

          context.create_group(name)
          nil
        end

        def ensure_host(name)
          existing = context.find_host(name)
          return existing unless existing.nil?

          context.create_host(name)
          nil
        end

        def array_value(payload, key)
          payload.fetch(key, []).map(&:to_s)
        end
      end
    end
  end
end
