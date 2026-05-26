module Moose
  module Inventory
    module Operations
      ##
      # Adds hosts and their optional group associations.
      #
      # This intentionally preserves the existing CLI progress output while
      # moving the inventory mutation rules out of the Thor command adapter.
      class AddHosts
        AUTOMATIC_GROUP = 'ungrouped'.freeze

        def initialize(db:, formatter:)
          @db = db
          @fmt = formatter
        end

        def call(names:, groups:)
          db.transaction do
            fmt.reset_indent

            names.each do |name|
              add_host(name, groups)
            end
          end
        end

        private

        attr_reader :db, :fmt

        def add_host(name, groups)
          puts "Add host '#{name}':"
          host, groups_dataset = create_or_find_host(name)

          groups.each do |group_name|
            add_group_association(host, name, group_name, groups_dataset)
          end

          add_automatic_group_if_needed(host, name)
          fmt.puts 2, '- All OK'
        end

        def create_or_find_host(name)
          fmt.puts 2, "- Creating host '#{name}'..."
          host = db.models[:host].find(name: name)
          groups_dataset = nil

          if host.nil?
            host = db.models[:host].create(name: name)
          else
            fmt.warn "The host '#{name}' already exists, skipping creation.\n"
            groups_dataset = host.groups_dataset
          end

          fmt.puts 4, '- OK'
          [host, groups_dataset]
        end

        def add_group_association(host, host_name, group_name, groups_dataset)
          return if group_name.nil? || group_name.empty?

          fmt.puts 2, "- Adding association {host:#{host_name} <-> group:#{group_name}}..."
          group = find_or_create_group(group_name)

          if association_exists?(groups_dataset, group_name)
            fmt.warn "Association {host:#{host_name} <-> group:#{group_name}} already exists, skipping creation.\n"
          else
            host.add_group(group)
          end

          fmt.puts 4, '- OK'
        end

        def find_or_create_group(name)
          group = db.models[:group].find(name: name)
          return group unless group.nil?

          fmt.warn "The group '#{name}' doesn't exist, but will be created.\n"
          db.models[:group].create(name: name)
        end

        def add_automatic_group_if_needed(host, host_name)
          groups_dataset = host.groups_dataset
          return if groups_dataset.nil? || groups_dataset.count != 0

          fmt.puts 2, "- Adding automatic association {host:#{host_name} <-> group:#{AUTOMATIC_GROUP}}..."
          host.add_group(automatic_group)
          fmt.puts 4, '- OK'
        end

        def automatic_group
          db.models[:group].find_or_create(name: AUTOMATIC_GROUP)
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end
      end
    end
  end
end
