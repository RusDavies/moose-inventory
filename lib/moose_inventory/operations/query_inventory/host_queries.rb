# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      class QueryInventory
        # Host-focused read queries.
        class HostQueries < BaseQuery
          def get_hosts(names:)
            names.each_with_object({}) do |name, results|
              host = context.find_host(name)
              next if host.nil?

              results[host.name.to_sym] = host_data(host)
            end
          end

          def list_hosts(filters: {})
            dataset = filtered_hosts_dataset(filters)
            return {} if dataset.nil?

            dataset.order(:id).all.to_h do |host|
              [host.name.to_sym, host_data(host)]
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

          private

          def host_data(host)
            {}.tap do |data|
              groups = host.groups_dataset.map(:name)
              data[:groups] = groups unless groups.empty?

              tags = host.tags_dataset.map(:name).sort
              data[:tags] = tags unless tags.empty?

              hostvars = variables_hash(host.hostvars_dataset)
              data[:hostvars] = hostvars unless hostvars.empty?
            end
          end

          def filtered_hosts_dataset(filters)
            dataset = context.hosts_dataset
            dataset = filter_hosts_by_groups(dataset, filters.fetch(:groups, []))
            return nil if dataset.nil?

            dataset = filter_hosts_by_tags(dataset, filters.fetch(:tags, []))
            return nil if dataset.nil?

            filter_hosts_by_variables(dataset, filters.fetch(:variables, {}))
          end

          def filter_hosts_by_groups(dataset, groups)
            groups.reduce(dataset) do |current_dataset, group_name|
              group = context.find_group(group_name)
              return nil if group.nil?

              current_dataset.where(id: context.db_dataset(:groups_hosts).where(group_id: group.id).select(:host_id))
            end
          end

          def filter_hosts_by_tags(dataset, tags)
            tags.reduce(dataset) do |current_dataset, tag_name|
              tag = context.find_tag(tag_name)
              return nil if tag.nil?

              current_dataset.where(id: context.db_dataset(:hosts_tags).where(tag_id: tag.id).select(:host_id))
            end
          end

          def filter_hosts_by_variables(dataset, variables)
            variables.reduce(dataset) do |current_dataset, (name, value)|
              current_dataset.where(
                id: context.db_dataset(:hostvars).where(name: name, value: value).select(:host_id)
              )
            end
          end

          def ansible_host_vars(name)
            results = {}
            host = context.find_host(name)
            results.merge!(variables_hash(host.hostvars_dataset)) unless host.nil?

            results[:_meta] = {
              hostvars: context.all_hosts.to_h do |entry|
                [entry.name.to_sym, variables_hash(entry.hostvars_dataset)]
              end
            }
            results
          end
        end
      end
    end
  end
end
