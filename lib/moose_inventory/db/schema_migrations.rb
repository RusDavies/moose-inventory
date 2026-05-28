# frozen_string_literal: true

module Moose
  module Inventory
    module DB
      # Schema definitions, ordered migrations, and schema-artifact helpers for Moose Inventory DB.
      # rubocop:disable Metrics/ModuleLength
      module SchemaMigrations
        SCHEMA_VERSION = 4

        TABLE_DEFINITIONS = {
          hosts: lambda do |db|
            db.create_table(:hosts) do
              primary_key :id
              column :name, :text, unique: true
            end
          end,
          hostvars: lambda do |db|
            db.create_table(:hostvars) do
              primary_key :id
              foreign_key :host_id
              column :name, :text
              column :value, :text
            end
          end,
          groups: lambda do |db|
            db.create_table(:groups) do
              primary_key :id
              column :name, :text, unique: true
            end
          end,
          groups_groups: lambda do |db|
            db.create_table(:groups_groups) do
              primary_key :id
              foreign_key :parent_id, :groups
              foreign_key :child_id, :groups
            end
          end,
          groupvars: lambda do |db|
            db.create_table(:groupvars) do
              primary_key :id
              foreign_key :group_id
              column :name, :text
              column :value, :text
            end
          end,
          groups_hosts: lambda do |db|
            db.create_table(:groups_hosts) do
              primary_key :id
              foreign_key :host_id, :hosts
              foreign_key :group_id, :groups
            end
          end,
          schema_info: lambda do |db|
            db.create_table(:schema_info) do
              primary_key :id
              column :version, :integer, null: false
            end
          end,
          audit_events: lambda do |db|
            db.create_table(:audit_events) do
              primary_key :id
              column :created_at, :text, null: false
              column :actor, :text
              column :command, :text, null: false
              column :action, :text, null: false
              column :entity_type, :text
              column :entity_name, :text
              column :details, :text
            end
          end,
          tags: lambda do |db|
            db.create_table(:tags) do
              primary_key :id
              column :name, :text, unique: true, null: false
            end
          end,
          hosts_tags: lambda do |db|
            db.create_table(:hosts_tags) do
              primary_key :id
              foreign_key :host_id, :hosts
              foreign_key :tag_id, :tags
            end
          end,
          groups_tags: lambda do |db|
            db.create_table(:groups_tags) do
              primary_key :id
              foreign_key :group_id, :groups
              foreign_key :tag_id, :tags
            end
          end
        }.freeze

        SCHEMA_MIGRATIONS = {
          1 => %i[hosts hostvars groups groups_groups groupvars groups_hosts schema_info],
          2 => %i[audit_events],
          3 => %i[tags hosts_tags groups_tags],
          4 => []
        }.freeze

        INDEX_DEFINITIONS = [
          { table: :hostvars, columns: %i[host_id name], unique: true, name: :idx_hostvars_host_id_name },
          { table: :groupvars, columns: %i[group_id name], unique: true, name: :idx_groupvars_group_id_name },
          { table: :groups_hosts, columns: %i[host_id group_id], unique: true,
            name: :idx_groups_hosts_host_id_group_id },
          { table: :groups_groups, columns: %i[parent_id child_id], unique: true,
            name: :idx_groups_groups_parent_id_child_id },
          { table: :hosts_tags, columns: %i[host_id tag_id], unique: true, name: :idx_hosts_tags_host_id_tag_id },
          { table: :groups_tags, columns: %i[group_id tag_id], unique: true, name: :idx_groups_tags_group_id_tag_id },
          { table: :groups_hosts, columns: %i[group_id host_id], unique: false,
            name: :idx_groups_hosts_group_id_host_id },
          { table: :groups_groups, columns: %i[child_id parent_id], unique: false,
            name: :idx_groups_groups_child_id_parent_id },
          { table: :hosts_tags, columns: %i[tag_id host_id], unique: false, name: :idx_hosts_tags_tag_id_host_id },
          { table: :groups_tags, columns: %i[tag_id group_id], unique: false, name: :idx_groups_tags_tag_id_group_id }
        ].freeze

        def migration_versions
          SCHEMA_MIGRATIONS.keys.sort
        end

        def schema_version
          return nil unless @db.table_exists?(:schema_info)

          @db[:schema_info].order(:id).last&.fetch(:version)
        end

        def migrate_schema!
          reject_future_schema!
          migration_versions.each do |version|
            next if schema_version.to_i >= version && !schema_migration_artifacts_missing?(version)

            apply_schema_migration!(version)
          end
        end

        def schema_migration_artifacts_missing?(version)
          schema_migration_tables_missing?(version) || (version == 4 && schema_indexes_missing?)
        end

        def schema_migration_tables_missing?(version)
          SCHEMA_MIGRATIONS.fetch(version).any? { |table_name| !@db.table_exists?(table_name) }
        end

        def schema_indexes_missing?
          INDEX_DEFINITIONS.any? do |definition|
            !@db.table_exists?(definition.fetch(:table)) || !index_exists?(definition.fetch(:table),
                                                                           definition.fetch(:name))
          end
        end

        def apply_schema_migration!(version)
          tables = SCHEMA_MIGRATIONS.fetch(version)
          tables.each { |table_name| create_table(table_name) }
          apply_schema_indexes! if version == 4
          record_schema_version!(version)
        end

        def apply_schema_indexes!
          clean_duplicate_index_rows!
          INDEX_DEFINITIONS.each { |definition| add_index(definition) }
        end

        def clean_duplicate_index_rows!
          dedupe_duplicate_rows!(:hostvars, %i[host_id name], value_columns: [:value])
          dedupe_duplicate_rows!(:groupvars, %i[group_id name], value_columns: [:value])
          dedupe_duplicate_rows!(:groups_hosts, %i[host_id group_id])
          dedupe_duplicate_rows!(:groups_groups, %i[parent_id child_id])
          dedupe_duplicate_rows!(:hosts_tags, %i[host_id tag_id])
          dedupe_duplicate_rows!(:groups_tags, %i[group_id tag_id])
        end

        def dedupe_duplicate_rows!(table_name, columns, value_columns: [])
          duplicate_keys(table_name, columns).each do |key|
            rows = @db[table_name].where(key).order(:id).all
            reject_conflicting_duplicates!(table_name, key, rows, value_columns)
            @db[table_name].where(id: rows.drop(1).map { |row| row.fetch(:id) }).delete
          end
        end

        def duplicate_keys(table_name, columns)
          @db[table_name]
            .select(*columns)
            .group(*columns)
            .having { count(id) > 1 }
            .all
        end

        def reject_conflicting_duplicates!(table_name, key, rows, value_columns)
          conflicts = value_columns.any? do |column|
            rows.map { |row| row[column] }.uniq.length > 1
          end
          return unless conflicts

          raise @exceptions[:moose], "Cannot add unique indexes because #{table_name} has conflicting duplicates " \
                                     "for #{key}. Resolve duplicate values before migrating."
        end

        def add_index(definition)
          return if index_exists?(definition.fetch(:table), definition.fetch(:name))

          @db.add_index(definition.fetch(:table), definition.fetch(:columns), unique: definition.fetch(:unique),
                                                                              name: definition.fetch(:name))
        end

        def index_exists?(table_name, index_name)
          @db.indexes(table_name).key?(index_name)
        end

        def record_schema_version!(version)
          unless @db.table_exists?(:schema_info)
            raise @exceptions[:moose],
                  'Cannot record schema version before schema_info exists.'
          end

          if @db[:schema_info].empty?
            @db[:schema_info].insert(version: version)
          else
            @db[:schema_info].update(version: version)
          end
        end

        def reject_future_schema!
          return unless @db.table_exists?(:schema_info)

          current_version = schema_version
          return if current_version.nil? || current_version <= SCHEMA_VERSION

          raise @exceptions[:moose], "Database schema version #{current_version} is newer than supported version " \
                                     "#{SCHEMA_VERSION}. Upgrade moose-inventory before using this database."
        end

        def create_tables
          TABLE_DEFINITIONS.each do |table_name, definition|
            create_table(table_name, definition)
          end
        end

        def create_table(table_name, definition = TABLE_DEFINITIONS.fetch(table_name))
          return if @db.table_exists?(table_name)

          definition.call(@db)
        end
      end
      # rubocop:enable Metrics/ModuleLength
    end
  end
end
