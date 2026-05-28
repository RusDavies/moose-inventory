# frozen_string_literal: true

require 'sequel'
require 'fileutils'
require 'json'

require_relative 'exceptions'
require_relative 'schema_migrations'

module Moose
  module Inventory
    ##
    # Module for DB-related functionality
    module DB
      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      @db = nil
      @models = nil
      @exceptions = nil
      attr_reader :db, :models, :exceptions

      extend SchemaMigrations

      SCHEMA_VERSION = SchemaMigrations::SCHEMA_VERSION
      TABLE_DEFINITIONS = SchemaMigrations::TABLE_DEFINITIONS
      SCHEMA_MIGRATIONS = SchemaMigrations::SCHEMA_MIGRATIONS
      INDEX_DEFINITIONS = SchemaMigrations::INDEX_DEFINITIONS

      MODEL_KEYS = {
        host: :Host,
        hostvar: :Hostvar,
        group: :Group,
        groupvar: :Groupvar,
        audit_event: :AuditEvent,
        tag: :Tag
      }.freeze

      BUSY_RETRY_LIMIT = 10
      BUSY_RETRY_BASE_DELAY_SECONDS = 0.05
      BUSY_RETRY_MAX_DELAY_SECONDS = 1.0

      #----------------------
      def self.init
        init_exceptions
        return unless @db.nil?

        Sequel::Model.plugin :json_serializer
        connect
        migrate_schema!
        bind_models!
      end

      def self.reset_runtime_state
        @db = nil
        @models = nil
        @exceptions = nil
      end

      #--------------------
      def self.init_exceptions
        @exceptions ||= {}
        @exceptions[:moose] ||= Moose::Inventory::DB::MooseDBException
      end

      #--------------------
      def self.transaction(&)
        raise('Database connection has not been established') if @db.nil?

        tries = 0

        begin
          @db.transaction(savepoint: true, &)
        rescue Sequel::DatabaseError => e
          raise unless busy_database_error?(e)

          tries += 1
          retry_busy_transaction(e, tries)
          retry
        rescue @exceptions[:moose] => e
          warn 'An error occurred during a transaction, any changes have been rolled back.'

          warn e.full_message(highlight: false, order: :top) if Moose::Inventory::Config.trace_enabled?
          abort("ERROR: #{e.message}")
        rescue SystemExit, StandardError
          warn 'An error occurred during a transaction, any changes have been rolled back.'
          raise
        end
      end

      #--------------------
      def self.reset
        raise('Database connection has not been established') if @db.nil?

        purge
        migrate_schema!
      end

      #===============================

      def self.bind_models!
        Sequel::DATABASES[0] = @db
        require_relative 'models'
        @models = MODEL_KEYS.transform_values do |name|
          Moose::Inventory::DB.const_get(name)
        end
      end

      def self.busy_database_error?(error)
        error.message.include?('BusyException')
      end

      def self.busy_retry_delay(tries)
        delay = BUSY_RETRY_BASE_DELAY_SECONDS * (2**(tries - 1))
        [delay, BUSY_RETRY_MAX_DELAY_SECONDS].min
      end

      def self.retry_busy_transaction(error, tries, sleeper: method(:sleep))
        if tries <= BUSY_RETRY_LIMIT
          warn error.message if Moose::Inventory::Config.trace_enabled?
          sleeper.call(busy_retry_delay(tries))
          return
        end

        warn('The database appears to be locked by another process, and ' \
             "did not become free after #{tries} tries. Giving up. ")
        raise error
      end

      #--------------------
      def self.purge
        return purge_sqlite_associations if sqlite_adapter?

        @db.drop_table(:hosts, :hostvars,
                       :groups, :groupvars, :group_hosts,
                       if_exists: true, cascade: true)
      end

      def self.status
        {
          adapter: normalized_adapter,
          schema_version: schema_version,
          expected_schema_version: SCHEMA_VERSION,
          tables: TABLE_DEFINITIONS.keys.to_h { |name| [name, @db.table_exists?(name)] },
          sqlite_file: sqlite_adapter? ? sqlite_file : nil
        }
      end

      def self.migrate!
        migrate_schema!
        status
      end

      def self.backup(path)
        raise @exceptions[:moose], 'Database backup is currently supported for sqlite3 only.' unless sqlite_adapter?

        source = sqlite_file
        raise @exceptions[:moose], "SQLite database file #{source} does not exist." unless File.exist?(source)

        destination = File.expand_path(path)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
        destination
      end

      def self.sqlite_adapter?
        normalized_adapter == 'sqlite3'
      end

      def self.sqlite_file
        File.expand_path(config_db_settings[:file])
      end

      def self.purge_sqlite_associations
        purge_sqlite_groups
        purge_sqlite_hosts
        Groupvar.all.each(&:destroy)
        Hostvar.all.each(&:destroy)
        AuditEvent.all.each(&:destroy) if @db.table_exists?(:audit_events)
        Tag.all.each(&:destroy) if @db.table_exists?(:tags)
      end

      def self.purge_sqlite_groups
        Group.all.each do |group|
          group.remove_all_hosts
          group.remove_all_groupvars
          group.remove_all_children
          group.remove_all_tags if @db.table_exists?(:groups_tags)
          group.destroy
        end
      end

      def self.purge_sqlite_hosts
        Host.all.each do |host|
          host.remove_all_groups
          host.remove_all_hostvars
          host.remove_all_tags if @db.table_exists?(:hosts_tags)
          host.destroy
        end
      end

      #--------------------
      def self.connect
        return unless @db.nil?

        case normalized_adapter
        when 'sqlite3'
          init_sqlite3
        when 'mysql'
          init_mysql
        when 'postgresql'
          init_postgresql
        else
          raise @exceptions[:moose],
                "database adapter #{normalized_adapter} is not yet supported."
        end
      end

      def self.config_db_settings
        Moose::Inventory::Config.db_settings
      end

      def self.normalized_adapter
        config_db_settings[:adapter].downcase
      end

      #--------------------
      def self.init_sqlite3
        require 'sqlite3'
        require 'fileutils'
        init_exceptions

        config = config_db_settings
        ensure_required_config_keys!(config, [:file], 'sqlite3')
        raise("SQLite3 DB 'file' cannot be empty") if config[:file].empty?

        dbfile = File.expand_path(config[:file])
        dbdir = File.dirname(dbfile)
        FileUtils.mkdir_p(dbdir)

        @db = Sequel.sqlite(dbfile)
      end

      #--------------------
      def self.init_mysql
        require 'mysql2'
        init_exceptions

        config = config_db_settings
        ensure_required_config_keys!(config, %i[host database user], 'mysql')
        password = db_password(config, 'mysql')

        @db = Sequel.mysql2(user: config[:user],
                            password: password,
                            host: config[:host],
                            database: config[:database])
      end

      #--------------------
      def self.init_postgresql
        require 'pg'
        init_exceptions

        config = config_db_settings
        ensure_required_config_keys!(config, %i[host database user], 'postgresql')
        password = db_password(config, 'postgresql')

        @db = Sequel.postgres(user: config[:user],
                              password: password,
                              host: config[:host],
                              database: config[:database])
      end

      def self.ensure_required_config_keys!(config, keys, adapter)
        keys.each do |key|
          next unless config[key].nil?

          raise @exceptions[:moose],
                "Expected key #{key} missing in #{adapter} configuration"
        end
      end

      #--------------------
      def self.db_password(config, adapter)
        return config[:password] unless config[:password].nil?

        if config[:password_env].nil?
          raise @exceptions[:moose],
                "Expected key password or password_env missing in #{adapter} configuration"
        end

        password = ENV.fetch(config[:password_env].to_s, nil)
        if password.nil? || password.empty?
          raise @exceptions[:moose],
                "Environment variable #{config[:password_env]} is not set for #{adapter} password"
        end

        password
      end
    end
  end
end
