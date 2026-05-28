# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Moose
  module Inventory
    module Operations
      # Validates and imports a portable inventory snapshot.
      class ImportInventorySnapshot
        Result = Struct.new(:created_hosts, :created_groups, :updated_variables, :associations, keyword_init: true)

        def initialize(context:)
          @context = context
        end

        def call(snapshot:)
          normalized = normalize_snapshot(snapshot)
          validate_snapshot!(normalized)

          context.transaction do
            apply_snapshot(normalized)
          end
        end

        private

        attr_reader :context

        def normalize_snapshot(snapshot)
          deep_stringify_keys(snapshot)
        end

        def validate_snapshot!(snapshot)
          raise_invalid('snapshot must be a mapping') unless snapshot.is_a?(Hash)
          raise_invalid('version must be 1') unless snapshot['version'].to_i == InventorySnapshot::VERSION
          raise_invalid('hosts must be a mapping') unless snapshot['hosts'].is_a?(Hash)
          raise_invalid('groups must be a mapping') unless snapshot['groups'].is_a?(Hash)

          validate_hosts!(snapshot)
          validate_groups!(snapshot)
          validate_group_cycles!(snapshot['groups'])
        end

        def validate_hosts!(snapshot)
          snapshot['hosts'].each do |name, payload|
            validate_entity_payload!(name, payload, 'host', allowed_keys: %w[groups vars])
            groups = array_value(payload, 'groups', label: "host '#{name}' groups")
            groups.each do |group_name|
              next if snapshot['groups'].key?(group_name)

              raise_invalid("host '#{name}' references unknown group '#{group_name}'")
            end
          end
        end

        def validate_groups!(snapshot)
          snapshot['groups'].each do |name, payload|
            validate_entity_payload!(name, payload, 'group', allowed_keys: %w[children vars])
            children = array_value(payload, 'children', label: "group '#{name}' children")
            children.each do |child_name|
              next if snapshot['groups'].key?(child_name)

              raise_invalid("group '#{name}' references unknown child group '#{child_name}'")
            end
          end
        end

        def validate_entity_payload!(name, payload, label, allowed_keys:)
          raise_invalid("#{label} name cannot be empty") if name.to_s.empty?
          raise_invalid("#{label} '#{name}' must be a mapping") unless payload.is_a?(Hash)

          unsupported = payload.keys - allowed_keys
          unless unsupported.empty?
            raise_invalid("#{label} '#{name}' has unsupported fields: #{unsupported.join(', ')}")
          end

          variables = payload.fetch('vars', {})
          raise_invalid("#{label} '#{name}' vars must be a mapping") unless variables.is_a?(Hash)
        end

        def validate_group_cycles!(groups)
          visiting = {}
          visited = {}

          groups.each_key do |name|
            visit_group!(name, groups, visiting, visited)
          end
        end

        def visit_group!(name, groups, visiting, visited)
          return if visited[name]

          raise_invalid("group hierarchy contains a cycle at '#{name}'") if visiting[name]

          visiting[name] = true
          array_value(groups[name], 'children', label: "group '#{name}' children").each do |child_name|
            visit_group!(child_name, groups, visiting, visited)
          end
          visiting.delete(name)
          visited[name] = true
        end

        def array_value(payload, key, label:)
          value = payload.fetch(key, [])
          raise_invalid("#{label} must be a list") unless value.is_a?(Array)

          value.map(&:to_s)
        end

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
            array_value(payload, 'children', label: "group '#{name}' children").each do |child_name|
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
            array_value(payload, 'groups', label: "host '#{name}' groups").each do |group_name|
              group = context.find_group(group_name)
              next unless host.groups_dataset[name: group_name].nil?

              host.add_group(group)
              result.associations += 1
            end
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

        def deep_stringify_keys(value)
          case value
          when Hash
            value.each_with_object({}) { |(key, val), result| result[key.to_s] = deep_stringify_keys(val) }
          when Array
            value.map { |entry| deep_stringify_keys(entry) }
          else
            value
          end
        end

        def raise_invalid(message)
          raise context.moose_exception_class, "Invalid inventory snapshot: #{message}."
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
