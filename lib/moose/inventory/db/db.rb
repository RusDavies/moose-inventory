require 'sequel'
require 'json'

require_relative './exceptions.rb'

module Moose
  module Inventory
    ##
    # Module for DB-related functionality
    module DB
      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      @db         = nil
      @models     = nil
      @exceptions = nil

      attr_reader :db
      attr_reader :models
      attr_reader :exceptions

      #----------------------
      def self.init
        # If we allow init more than once, then the db connection is remade,
        # which changes Sequel:DATABASES[0], thereby invalidating the sequel
        # models.  This causes unexpected behavour. That is to say, because
        # of the way Sequel initializes models, this method is not idempotent.
        # In our single-shot application, this shouldn't be a problem. However,
        # our unit tests like to call init multiple times, which borks things.
        # So, we allow init only once, gated by whether @db is nil. In effect,
        # this means we pool the DB connection for the life of the application.
        # Again, not a problem for our one-shot app, but it may be an issue in
        # long-running code. Personally, I don't like this pooling regime - 
        # perhaps I'm not understanding how it's supposed to be used? 
        #
        # TODO: can the models be refreshed, to make then again valid? What if
        #       we "load" instead of "require" the models?
        # UPDATE: Nope, still borks even if we use a load.
        #
        # @db = nil            # <- fails for unit tests
        return unless @db.nil? # <- works for unit tests

        Sequel::Model.plugin :json_serializer
        connect
        create_tables

        # Make our models work
        Sequel::DATABASES[0] = @db
        require_relative 'models'
        # load( load_dir = File.join(File.dirname(__FILE__), "models.rb") )

        # For convenience
        @models = {}
        @models[:host]     = Moose::Inventory::DB::Host
        @models[:hostvar]  = Moose::Inventory::DB::Hostvar
        @models[:group]    = Moose::Inventory::DB::Group
        @models[:groupvar] = Moose::Inventory::DB::Groupvar

        @exceptions = {}
        @exceptions[:moose] = Moose::Inventory::DB::MooseDBException

      end

      #--------------------
      def self.transaction
        fail('Database connection has not been established') if @db.nil?
        begin
          @db.transaction(savepoint: true) do
            yield
          end

        rescue @exceptions[:moose] => e
          warn 'An error occurred during a transaction, any changes have been rolled back.'

          if Moose::Inventory::Config._confopts[:trace] == true
            abort("ERROR: #{e}")
          else          
            abort("ERROR: #{e.message}")
          end

        rescue Exception => e
          warn 'An error occurred during a transaction, any changes have been rolled back.'
          raise e
        end
      end

      #--------------------
      def self.reset
        fail('Database connection has not been established') if @db.nil?
        # @debug << 'reset'
        purge
        create_tables
      end

      #===============================

      private

      #--------------------
      def self.purge # rubocop:disable Metrics/AbcSize
        adapter = Moose::Inventory::Config._settings[:config][:db][:adapter]
        adapter.downcase!

        if adapter == 'sqlite3'
          # HACK: SQLite3 supposedly supports CASCADE, see
          # https://www.sqlite.org/foreignkeys.html#fk_actions
          # However, when we do a drop_table with :cascade=>true
          # on an sqlite3 database, it throws errors regarding
          # foreign keys constraints. Instead, the following is
          # less efficient, but does work.

          Group.all.each do |g|
            g.remove_all_hosts
            g.remove_all_groupvars
            g.destroy
          end

          Host.all.each do |h|
            h.remove_all_groups
            h.remove_all_hostvars
            h.destroy
          end

          Groupvar.all.each(&:destroy)
          Hostvar.all.each(&:destroy)

        else
          @db.drop_table(:hosts, :hostvars,
                         :groups,  :groupvars, :group_hosts,
                         if_exists: true, cascade: true)
        end
      end

      #--------------------
      def self.create_tables # rubocop:disable Metrics/AbcSize
        unless @db.table_exists? :hosts
          @db.create_table(:hosts) do
            primary_key :id
            column :name, :text, unique: true
          end
        end

        unless @db.table_exists? :hostvars
          @db.create_table(:hostvars) do
            primary_key :id
            foreign_key :host_id
            column :name, :text
            column :value, :text
          end
        end

        unless @db.table_exists? :groups
          @db.create_table(:groups) do
            primary_key :id
            column :name, :text, unique: true
          end
        end

        unless @db.table_exists? :groupvars
          @db.create_table(:groupvars) do
            primary_key :id
            foreign_key :group_id
            column :name, :text
            column :value, :text
          end
        end

        unless @db.table_exists? :groups_hosts
          @db.create_table(:groups_hosts) do
            primary_key :id
            foreign_key :host_id,  :hosts
            foreign_key :group_id, :groups
          end
        end
      end

      #--------------------
      def self.connect
        return unless @db.nil?

        adapter = Moose::Inventory::Config._settings[:config][:db][:adapter]
        adapter.downcase!

        case adapter
        when 'sqlite3'
          init_sqlite3

        when 'msqsql'
          init_mysql

        when 'postgresql'
          init_postgresql

        else
          fail @exceptions[:moose ], 
            "database adapter #{adapter} is not yet supported."
        end
      end

      #--------------------
      def self.init_sqlite3 # rubocop:disable Metrics/AbcSize
        require 'sqlite3'

        # Quick check that expected keys are at least present & sensible
        config = Moose::Inventory::Config._settings[:config][:db]
        [:file].each do |key|
          if config[key].nil?
            fail @exceptions[:moose ], 
              "Expected key #{key} missing in sqlite3 configuration"
          end
        end
        config[:file].empty? && fail("SQLite3 DB 'file' cannot be empty")

        # Make sure the directory exists
        dbfile = File.expand_path(config[:file])
        dbdir = File.dirname(dbfile)
        Dir.mkdir(dbdir) unless Dir.exist?(dbdir)

        # Create and/or open the database file
        @db = Sequel.sqlite(dbfile)
      end

      #--------------------
      def self.init_mysql
        require 'mysql'

        # TODO: native MySQL driver vs the pure ruby one?
        #       Sequel requires the native on.
        # gem('mysql')

        # Quick check that expected keys are at least present
        config = Moose::Inventory::Config._settings[:config][:db]
        [:host, :database, :user, :password].each do |key|
          if config[key].nil?
            fail @exceptions[:moose ],
              "Expected key #{key} missing in mysql configuration"
          end
        end

        @db = Sequel.mysql(user: config[:user],
                           password: config[:password],
                           host: config[:host],
                           database: config[:database]
                          )
      end
    end
  end
end
