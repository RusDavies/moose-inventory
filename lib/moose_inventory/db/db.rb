# frozen_string_literal: true

require 'sequel'
require 'json'

require_relative 'exceptions'

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
        end
      }.freeze

      MODEL_KEYS = {
        host: :Host,
        hostvar: :Hostvar,
        group: :Group,
        groupvar: :Groupvar
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
        create_tables
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
        create_tables
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

      def self.sqlite_adapter?
        normalized_adapter == 'sqlite3'
      end

      def self.purge_sqlite_associations
        Group.all.each do |group|
          group.remove_all_hosts
          group.remove_all_groupvars
          group.remove_all_children
          group.destroy
        end

        Host.all.each do |host|
          host.remove_all_groups
          host.remove_all_hostvars
          host.destroy
        end

        Groupvar.all.each(&:destroy)
        Hostvar.all.each(&:destroy)
      end

      #--------------------
      def self.create_tables
        TABLE_DEFINITIONS.each do |table_name, definition|
          next if @db.table_exists?(table_name)

          definition.call(@db)
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
