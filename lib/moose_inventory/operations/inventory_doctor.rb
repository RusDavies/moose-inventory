# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Moose
  module Inventory
    module Operations
      # Runs read-only inventory health checks for humans and CI.
      class InventoryDoctor
        AUTOMATIC_GROUP = 'ungrouped'

        def initialize(context:, config: Moose::Inventory::Config)
          @context = context
          @config = config
        end

        def call
          issues = []
          issues.concat(check_database_config)
          issues.concat(check_plaintext_password_config)
          issues.concat(check_hosts_only_in_automatic_group)
          issues.concat(check_orphaned_groups)
          issues.concat(check_empty_groups)
          issues.concat(check_duplicateish_names)
          issues.concat(check_invalid_variables)
          issues.concat(check_group_cycles)

          {
            ok: issues.empty?,
            issue_count: issues.length,
            issues: issues
          }
        end

        private

        attr_reader :context, :config

        def check_database_config
          settings = config.db_settings
          return [issue('missing_db_config', 'error', 'Database configuration is missing.')] unless settings.is_a?(Hash)
          return [] if settings[:adapter].to_s.strip != ''

          [issue('missing_db_adapter', 'error', 'Database adapter is missing from configuration.')]
        rescue StandardError => e
          [issue('missing_db_config', 'error', "Database configuration could not be read: #{e.message}")]
        end

        def check_plaintext_password_config
          settings = config.db_settings
          return [] unless settings.is_a?(Hash) && settings.key?(:password)

          [
            issue('plaintext_password_config', 'warning',
                  'Database configuration uses plaintext password; prefer password_env.')
          ]
        end

        def check_hosts_only_in_automatic_group
          context.all_hosts.filter_map do |host|
            groups = host.groups_dataset.map(:name)
            next unless groups == [AUTOMATIC_GROUP]

            issue('host_only_in_ungrouped', 'warning', "Host '#{host.name}' is only in automatic group 'ungrouped'.",
                  subject: host.name)
          end
        end

        def check_orphaned_groups
          context.all_groups.filter_map do |group|
            next if group.name == AUTOMATIC_GROUP
            next unless group.parents_dataset.empty? && group.hosts_dataset.empty?

            issue('orphaned_group', 'warning', "Group '#{group.name}' has no parents and no hosts.",
                  subject: group.name)
          end
        end

        def check_empty_groups
          context.all_groups.filter_map do |group|
            next if group.name == AUTOMATIC_GROUP
            next unless group.hosts_dataset.empty? && group.children_dataset.empty? && group.groupvars_dataset.empty?

            issue('empty_group', 'warning', "Group '#{group.name}' is empty.", subject: group.name)
          end
        end

        def check_duplicateish_names
          host_issues = duplicateish_issues(context.all_hosts.map(&:name), 'host')
          group_issues = duplicateish_issues(context.all_groups.map(&:name), 'group')
          host_issues + group_issues
        end

        def duplicateish_issues(names, label)
          names.group_by { |name| normalize_name(name) }.filter_map do |normalized, originals|
            unique = originals.uniq
            next if normalized.empty? || unique.length < 2

            issue("duplicateish_#{label}_names", 'warning',
                  "#{label.capitalize} names look duplicate-ish: #{unique.sort.join(', ')}.", subject: unique.sort)
          end
        end

        def normalize_name(name)
          name.to_s.downcase.gsub(/[^a-z0-9]/, '')
        end

        def check_invalid_variables
          host_var_issues = context.all_hosts.flat_map do |host|
            invalid_variable_issues(host.hostvars_dataset, "host '#{host.name}'")
          end
          group_var_issues = context.all_groups.flat_map do |group|
            invalid_variable_issues(group.groupvars_dataset, "group '#{group.name}'")
          end
          host_var_issues + group_var_issues
        end

        def invalid_variable_issues(dataset, owner)
          dataset.filter_map do |variable|
            next unless variable.name.to_s.strip.empty? || variable.value.nil?

            issue('invalid_variable_shape', 'error', "Variable on #{owner} has an empty name or nil value.",
                  subject: owner)
          end
        end

        def check_group_cycles
          groups = context.all_groups.to_h { |group| [group.name, group.children_dataset.map(:name)] }
          visiting = {}
          visited = {}
          cycles = []

          state = { groups: groups, visiting: visiting, visited: visited, cycles: cycles }
          groups.each_key do |name|
            visit_group(name, state, [])
          end

          cycles.uniq.map do |cycle|
            issue('circular_group_relationship', 'error', "Group hierarchy contains a cycle: #{cycle.join(' -> ')}.",
                  subject: cycle)
          end
        end

        def visit_group(name, state, path)
          return if state[:visited][name]

          if state[:visiting][name]
            cycle_start = path.index(name) || 0
            state[:cycles] << (path[cycle_start..] + [name])
            return
          end

          state[:visiting][name] = true
          state[:groups].fetch(name, []).each do |child|
            visit_group(child, state, path + [name])
          end
          state[:visiting].delete(name)
          state[:visited][name] = true
        end

        def issue(id, severity, message, subject: nil)
          {
            id: id,
            severity: severity,
            message: message,
            subject: subject
          }.compact
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
