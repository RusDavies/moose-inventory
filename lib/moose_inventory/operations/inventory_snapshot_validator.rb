# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Normalizes and validates portable inventory snapshot input before import.
      class InventorySnapshotValidator
        def initialize(context:)
          @context = context
        end

        def call(snapshot:)
          normalized = deep_stringify_keys(snapshot)
          validate_snapshot!(normalized)
          normalized
        end

        private

        attr_reader :context

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
            validate_entity_payload!(name, payload, 'host', allowed_keys: %w[groups tags vars])
            groups = array_value(payload, 'groups', label: "host '#{name}' groups")
            groups.each do |group_name|
              next if snapshot['groups'].key?(group_name)

              raise_invalid("host '#{name}' references unknown group '#{group_name}'")
            end
          end
        end

        def validate_groups!(snapshot)
          snapshot['groups'].each do |name, payload|
            validate_entity_payload!(name, payload, 'group', allowed_keys: %w[children tags vars])
            children = array_value(payload, 'children', label: "group '#{name}' children")
            children.each do |child_name|
              next if snapshot['groups'].key?(child_name)

              raise_invalid("group '#{name}' references unknown child group '#{child_name}'")
            end
          end
        end

        def validate_entity_payload!(name, payload, label, allowed_keys:)
          raise_invalid("#{label} name cannot be empty") if blank_string?(name)
          raise_invalid("#{label} '#{name}' must be a mapping") unless payload.is_a?(Hash)

          unsupported = payload.keys - allowed_keys
          unless unsupported.empty?
            raise_invalid("#{label} '#{name}' has unsupported fields: #{unsupported.join(', ')}")
          end

          variables = payload.fetch('vars', {})
          raise_invalid("#{label} '#{name}' vars must be a mapping") unless variables.is_a?(Hash)
          variables.each_key do |variable_name|
            raise_invalid("#{label} '#{name}' variable name cannot be empty") if blank_string?(variable_name)
          end

          array_value(payload, 'tags', label: "#{label} '#{name}' tags")
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

        def deep_stringify_keys(value)
          case value
          when Hash
            stringify_hash_keys(value)
          when Array
            value.map { |entry| deep_stringify_keys(entry) }
          else
            value
          end
        end

        def stringify_hash_keys(hash)
          hash.each_with_object({}) do |(key, val), result|
            normalized_key = key.to_s
            raise_invalid("duplicate normalized key '#{normalized_key}'") if result.key?(normalized_key)

            result[normalized_key] = deep_stringify_keys(val)
          end
        end

        def blank_string?(value)
          value.to_s.strip.empty?
        end

        def raise_invalid(message)
          raise context.moose_exception_class, "Invalid inventory snapshot: #{message}."
        end
      end
    end
  end
end
