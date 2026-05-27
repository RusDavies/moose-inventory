# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      class QueryInventory
        # Group-focused read queries.
        class GroupQueries < BaseQuery
          def get_groups(names:)
            names.each_with_object({}) do |name, results|
              group = context.find_group(name)
              next if group.nil?

              results[group.name.to_sym] = group_data(group)
            end
          end

          def list_groups(ansible:)
            context.all_groups.each_with_object({}) do |group, results|
              hosts = group.hosts_dataset.map(:name)
              next if hide_empty_automatic_group?(group, hosts)

              results[group.name.to_sym] = list_group_data(group, hosts, ansible: ansible)
            end
          end

          def list_group_vars(names:, ansible:)
            return {} if names.empty?
            return ansible_group_vars(names.first) if ansible

            names.each_with_object({}) do |name, results|
              group = context.find_group(name)
              next if group.nil?

              results[name.to_sym] = variables_hash(group.groupvars_dataset)
            end
          end

          private

          def group_data(group)
            {}.tap do |data|
              hosts = group.hosts_dataset.map(:name)
              data[:hosts] = hosts unless hosts.empty?

              children = group.children_dataset.map(:name)
              data[:children] = children unless children.empty?

              groupvars = variables_hash(group.groupvars_dataset)
              data[:groupvars] = groupvars unless groupvars.empty?
            end
          end

          def hide_empty_automatic_group?(group, hosts)
            group.name == 'ungrouped' && hosts.empty?
          end

          def list_group_data(group, hosts, ansible:)
            {}.tap do |data|
              data[:hosts] = hosts if ansible || !hosts.empty?

              children = group.children_dataset.map(:name)
              data[:children] = children unless children.empty?

              append_group_vars(data, group, ansible: ansible)
            end
          end

          def append_group_vars(data, group, ansible:)
            groupvars = variables_hash(group.groupvars_dataset)
            return if groupvars.empty?

            data[ansible ? :vars : :groupvars] = groupvars
          end

          def ansible_group_vars(name)
            group = context.find_group(name)
            return {} if group.nil?

            variables_hash(group.groupvars_dataset)
          end
        end
      end
    end
  end
end
