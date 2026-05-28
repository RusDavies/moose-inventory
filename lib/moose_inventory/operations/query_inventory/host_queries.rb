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
            context.all_hosts.select { |host| host_matches_filters?(host, filters) }.to_h do |host|
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

          def host_matches_filters?(host, filters)
            groups_match?(host, filters.fetch(:groups, [])) &&
              tags_match?(host, filters.fetch(:tags, [])) &&
              variables_match?(host, filters.fetch(:variables, {}))
          end

          def groups_match?(host, groups)
            return true if groups.empty?

            host_groups = host.groups_dataset.map(:name)
            (groups - host_groups).empty?
          end

          def tags_match?(host, tags)
            return true if tags.empty?

            host_tags = host.tags_dataset.map(:name)
            (tags - host_tags).empty?
          end

          def variables_match?(host, variables)
            return true if variables.empty?

            hostvars = variables_hash(host.hostvars_dataset).transform_keys(&:to_s)
            variables.all? { |name, value| hostvars[name] == value }
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
