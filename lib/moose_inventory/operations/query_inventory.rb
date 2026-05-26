# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      # Read-only inventory query seam for host/group CLI commands.
      class QueryInventory
        def initialize(context:)
          @context = context
        end

        def get_hosts(names:)
          names.each_with_object({}) do |name, results|
            host = context.find_host(name)
            next if host.nil?

            host_data = {}
            groups = host.groups_dataset.map(:name)
            host_data[:groups] = groups unless groups.empty?

            hostvars = variables_hash(host.hostvars_dataset)
            host_data[:hostvars] = hostvars unless hostvars.empty?

            results[host.name.to_sym] = host_data
          end
        end

        def list_hosts
          context.all_hosts.each_with_object({}) do |host, results|
            host_data = { groups: host.groups_dataset.map(:name) }
            hostvars = variables_hash(host.hostvars_dataset)
            host_data[:hostvars] = hostvars unless hostvars.empty?
            results[host.name.to_sym] = host_data
          end
        end

        def list_host_vars(names:, ansible:)
          return ansible_host_vars(names.first) if ansible

          names.each_with_object({}) do |name, results|
            host = context.find_host(name)
            next if host.nil?

            results[name.to_sym] = variables_hash(host.hostvars_dataset)
          end
        end

        def get_groups(names:)
          names.each_with_object({}) do |name, results|
            group = context.find_group(name)
            next if group.nil?

            group_data = {}
            hosts = group.hosts_dataset.map(:name)
            group_data[:hosts] = hosts unless hosts.empty?
            children = group.children_dataset.map(:name)
            group_data[:children] = children unless children.empty?
            groupvars = variables_hash(group.groupvars_dataset)
            group_data[:groupvars] = groupvars unless groupvars.empty?

            results[group.name.to_sym] = group_data
          end
        end

        def list_groups(ansible:)
          context.all_groups.each_with_object({}) do |group, results|
            hosts = group.hosts_dataset.map(:name)
            next if hide_empty_automatic_group?(group, hosts)

            results[group.name.to_sym] = list_group_data(group, hosts, ansible: ansible)
          end
        end

        def hide_empty_automatic_group?(group, hosts)
          group.name == 'ungrouped' && hosts.empty?
        end

        def list_group_data(group, hosts, ansible:)
          {}.tap do |group_data|
            include_hosts_in_list_group_data(group_data, hosts, ansible: ansible)
            children = group.children_dataset.map(:name)
            group_data[:children] = children unless children.empty?

            groupvars = variables_hash(group.groupvars_dataset)
            add_groupvars_to_list_group_data(group_data, groupvars, ansible: ansible)
          end
        end

        def include_hosts_in_list_group_data(group_data, hosts, ansible:)
          return if hosts.empty? && !ansible

          group_data[:hosts] = hosts
        end

        def add_groupvars_to_list_group_data(group_data, groupvars, ansible:)
          return if groupvars.empty?

          key = ansible ? :vars : :groupvars
          group_data[key] = groupvars
        end

        def list_group_vars(names:, ansible:)
          return {} if names.empty?

          if ansible
            group = context.find_group(names.first)
            return {} if group.nil?

            return variables_hash(group.groupvars_dataset)
          end

          names.each_with_object({}) do |name, results|
            group = context.find_group(name)
            next if group.nil?

            results[name.to_sym] = variables_hash(group.groupvars_dataset)
          end
        end

        private

        attr_reader :context

        def ansible_host_vars(name)
          results = {}
          host = context.find_host(name)
          results.merge!(variables_hash(host.hostvars_dataset)) unless host.nil?

          meta = { hostvars: {} }
          context.all_hosts.each do |entry|
            meta[:hostvars][entry.name.to_sym] = variables_hash(entry.hostvars_dataset)
          end
          results[:_meta] = meta
          results
        end

        def variables_hash(dataset)
          dataset.to_h { |variable| [variable[:name].to_sym, variable[:value]] }
        end
      end
    end
  end
end
