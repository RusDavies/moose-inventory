require 'sequel'
require 'json'

require_relative './exceptions.rb'

module Moose
  module Inventory
    module DB
      extend self
      @_db     = nil
      attr_reader :_db
      #----------------------
      def self.init
        @_db = nil

        # Use the JSON serializer
        Sequel::Model.plugin :json_serializer

        # Connect (note, this clobbers @_db and Sequel::DATABASES[0]
        self.connect

        # Make our models work
        Sequel::DATABASES[0] = @_db
        require_relative "models"
        
        # Make sure our tables are set up
        self.create_tables
      end

      #--------------------
      def self.transaction
        fail("Database connection has not been established") if @_db.nil?
        #state = 'pending'
        begin
          # require_relative "models"
          @_db.transaction do
            #@_db.after_commit{state   = 'committed'}
            #@_db.after_rollback{state = 'rolled back'}
            yield
          end

        rescue Moose::Inventory::DB::MooseDBException => e
          #STDERR.puts "DEBUG: db state: #{state}"
          abort("ERROR: #{e.message}")

        rescue Exception => e
          #STDERR.puts "DEBUG: db state: #{state}"
          raise e
        end
      end

      #--------------------
      def self.reset
        fail("Database connection has not been established") if @_db.nil?
        self.purge
        self.create_tables
      end
      
      #===============================
      #private
      
      #--------------------
      def self.purge
        adapter = Moose::Inventory::Config._settings[:config][:db][:adapter].downcase
        if adapter == 'sqlite3' 
           # SQLite3 supposedly supports CASCADE, see https://www.sqlite.org/foreignkeys.html#fk_actions
           # However, when we do a drop_table with :cascade=>true on an sqlite3 database, it throws
           # errors regarding foreign keys constraints. Instead, the following is inefficient, but works. 
           Group.all.each do |g|
             g.remove_all_hosts
             g.remove_all_groupvars
             g.destroy
           end
       
           Groupvar.all.each do |gv|
             #gv.remove_all_groups
             gv.destroy
           end
       
           Host.all.each do |h|
             h.remove_all_groups
             h.remove_all_hostvars
             h.destroy
           end
       
           Hostvar.all.each do |hv|
             #hv.remove_all_hosts
             hv.destroy
           end
          
        else
          # Assuming the foreign key issue is just with sqlite3 (I haven't yet tested other DBs) then
          # this *should* work for mysql/postgres etc, and be more efficient.
          @_db.drop_table(:hosts, :hostvars,  :groups,  :groupvars, :group_hosts, 
                          :if_exists=>true, :cascade=>true)
        end
      end
      
      #--------------------
      def self.create_tables
        unless @_db.table_exists? :hosts
          @_db.create_table(:hosts) do
            primary_key :id
            column :name, :text, :unique=>true
          end
        end

        unless @_db.table_exists? :hostvars
          @_db.create_table(:hostvars) do
            primary_key    :id
            foreign_key    :host_id
            column :name,  :text
            column :value, :text
          end
        end

        unless @_db.table_exists? :groups
          @_db.create_table(:groups) do
            primary_key   :id
            column :name, :text, :unique=>true
          end
        end

        unless @_db.table_exists? :groupvars
          @_db.create_table(:groupvars) do
            primary_key :id
            foreign_key :group_id
            column :name, :text
            column :value, :text # TODO: Do we need to serialize data into here, as, say, JSON?
          end
        end

        unless @_db.table_exists? :groups_hosts
          @_db.create_table(:groups_hosts) do
            primary_key :id
            foreign_key :host_id,  :hosts
            foreign_key :group_id, :groups
          end
        end
      end

      #--------------------
      def self.connect
        return if !@_db.nil?

        adapter = Moose::Inventory::Config._settings[:config][:db][:adapter].downcase

        case adapter
        when "sqlite3"
          self.init_sqlite3

        when "msqsql"
          self.init_mysql

        when "postgresql"
          self.init_postgresql

        else
          fail("database adapter #{adapter} is not yet supported.")
        end
      end

      #--------------------
      def self.init_sqlite3
        require 'sqlite3'

        # Quick check that expected keys are at least present & sensible
        config = Moose::Inventory::Config._settings[:config][:db]
        [:file].each do |key|
          fail("Expected key #{key} missing in sqlite3 configuration") if config[key].nil?
        end
        fail("SQLite3 DB 'file' cannot be empty") if config[:file].empty?

        # Make sure the directory exists
        dbfile = File.expand_path(config[:file])
        dbdir = File.dirname(dbfile)
        Dir::mkdir(dbdir) unless Dir.exists?(dbdir)

        # Create and/or open the database file
        @_db = Sequel.sqlite(dbfile)
      end

      #--------------------
      def self.init_mysql
        require 'mysql'

        # TODO: native MySQL driver vs the pure ruby one? Sequel requires the native on.
        # gem('mysql')

        # Quick check that expected keys are at least present
        config = Moose::Inventory::Config._settings[:config][:db]
        [:host, :database, :user, :password].each do |key|
          fail("Expected key #{key} missing in mysql configuration") if config[key].nil?
        end

        @_db = Sequel.mysql(:user => config[:user],
        :password=>config[:password],
        :host => config[:host],
        :database => config[:database])
      end
    end
  end
end
