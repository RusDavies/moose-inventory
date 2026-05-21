require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'Moose::Inventory::DB' do
  def with_db_config(db_config)
    saved_db = @db.instance_variable_get(:@db)
    saved_settings = @config._settings.dup

    begin
      @db.instance_variable_set(:@db, nil)
      @config._settings.clear
      @config._settings[:config] = { db: db_config }
      yield
    ensure
      current_db = @db.instance_variable_get(:@db)
      current_db.disconnect if current_db.respond_to?(:disconnect)
      @db.instance_variable_set(:@db, saved_db)
      @config._settings.clear
      @config._settings.merge!(saved_settings)
    end
  end

  #=============================
  # Initialization
  #

  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join(spec_root, 'config/config.yml'),
      format:  'yaml',
      env:     'test',
    }

    @mockargs = []
    @mockarg_parts.each do |key, val|
      @mockargs << "--#{key}"
      @mockargs << val
    end

    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @db = Moose::Inventory::DB
  end

  #=============================
  # Tests
  #

  describe '.init()' do
    it 'should be responsive' do
      expect(@db.respond_to?(:init)).to eq(true)
    end

    it 'shouldn\'t throw an error' do
      failed = false
      # rubocop:disable Lint/RescueException
      begin
        @db.init
      rescue Exception => e
        p e
        failed = true
      end
      # rubocop:enable Lint/RescueException

      expect(failed).to eq(false)
    end

    it 'raises a Moose DB exception for unsupported adapters' do
      saved_db = @db.instance_variable_get(:@db)
      saved_models = @db.instance_variable_get(:@models)
      saved_exceptions = @db.instance_variable_get(:@exceptions)
      saved_settings = @config._settings.dup

      begin
        @db.instance_variable_set(:@db, nil)
        @db.instance_variable_set(:@models, nil)
        @db.instance_variable_set(:@exceptions, nil)
        @config._settings.clear
        @config._settings[:config] = { db: { adapter: 'unsupported' } }

        expect { @db.init }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /database adapter unsupported is not yet supported/
        )
        expect(@db.exceptions[:moose]).to eq(Moose::Inventory::DB::MooseDBException)
      ensure
        @db.instance_variable_set(:@db, saved_db)
        @db.instance_variable_set(:@models, saved_models)
        @db.instance_variable_set(:@exceptions, saved_exceptions)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
      end
    end
  end

  describe '.init_exceptions()' do
    it 'is responsive' do
      expect(@db.respond_to?(:init_exceptions)).to eq(true)
    end
  end

  describe '.connect()' do
    it 'dispatches the documented sqlite3 adapter to the sqlite initializer' do
      with_db_config(adapter: 'sqlite3') do
        expect(@db).to receive(:init_sqlite3) do
          @db.instance_variable_set(:@db, :sqlite_connection)
        end
        @db.connect
        expect(@db.db).to eq(:sqlite_connection)
      end
    end

    it 'dispatches the documented mysql adapter to the mysql initializer' do
      with_db_config(adapter: 'mysql') do
        expect(@db).to receive(:init_mysql) do
          @db.instance_variable_set(:@db, :mysql_connection)
        end
        @db.connect
        expect(@db.db).to eq(:mysql_connection)
      end
    end

    it 'dispatches the documented postgresql adapter to the postgresql initializer' do
      with_db_config(adapter: 'postgresql') do
        expect(@db).to receive(:init_postgresql) do
          @db.instance_variable_set(:@db, :postgresql_connection)
        end
        @db.connect
        expect(@db.db).to eq(:postgresql_connection)
      end
    end
  end

  describe '.init_sqlite3()' do
    it 'raises a Moose DB exception when the configured database file is missing' do
      with_db_config(adapter: 'sqlite3') do
        expect { @db.init_sqlite3 }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /Expected key file missing in sqlite3 configuration/
        )
      end
    end

    it 'creates nested parent directories for configured database files' do
      saved_db = @db.instance_variable_get(:@db)
      saved_settings = @config._settings.dup
      tmpdir = Dir.mktmpdir('moose-inventory-sqlite')
      nested_dbfile = File.join(tmpdir, 'one', 'two', 'inventory.db')

      begin
        @db.instance_variable_set(:@db, nil)
        @config._settings.clear
        @config._settings[:config] = {
          db: {
            adapter: 'sqlite3',
            file: nested_dbfile,
          },
        }

        @db.init_sqlite3

        expect(File.directory?(File.dirname(nested_dbfile))).to eq(true)
        expect(File.file?(nested_dbfile)).to eq(true)
      ensure
        current_db = @db.instance_variable_get(:@db)
        current_db.disconnect if current_db.respond_to?(:disconnect)
        @db.instance_variable_set(:@db, saved_db)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
        FileUtils.remove_entry(tmpdir) if tmpdir && Dir.exist?(tmpdir)
      end
    end
  end

  describe '.init_mysql()' do
    it 'raises a Moose DB exception when a required connection key is missing' do
      with_db_config(
        adapter: 'mysql',
        database: 'moose_inventory_test',
        user: 'moose',
        password: 'secret'
      ) do
        expect { @db.init_mysql }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /Expected key host missing in mysql configuration/
        )
      end
    end

    it 'uses the mysql2 Sequel adapter with configured connection settings' do
      saved_db = @db.instance_variable_get(:@db)
      saved_settings = @config._settings.dup
      mysql_config = {
        adapter: 'mysql',
        host: 'localhost',
        database: 'moose_inventory_test',
        user: 'moose',
        password: 'secret',
      }

      begin
        @db.instance_variable_set(:@db, nil)
        @config._settings.clear
        @config._settings[:config] = { db: mysql_config }

        expect(Sequel).to receive(:mysql2).with(
          user: 'moose',
          password: 'secret',
          host: 'localhost',
          database: 'moose_inventory_test'
        ).and_return(:mysql2_connection)

        @db.init_mysql
        expect(@db.db).to eq(:mysql2_connection)
      ensure
        @db.instance_variable_set(:@db, saved_db)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
      end
    end
  end

  describe '.init_postgresql()' do
    it 'raises a Moose DB exception when a required connection key is missing' do
      with_db_config(
        adapter: 'postgresql',
        host: 'localhost',
        database: 'moose_inventory_test',
        password: 'secret'
      ) do
        expect { @db.init_postgresql }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /Expected key user missing in postgresql configuration/
        )
      end
    end

    it 'uses the postgres Sequel adapter with configured connection settings' do
      saved_db = @db.instance_variable_get(:@db)
      saved_settings = @config._settings.dup
      postgresql_config = {
        adapter: 'postgresql',
        host: 'localhost',
        database: 'moose_inventory_test',
        user: 'moose',
        password: 'secret',
      }

      begin
        @db.instance_variable_set(:@db, nil)
        @config._settings.clear
        @config._settings[:config] = { db: postgresql_config }

        expect(Sequel).to receive(:postgres).with(
          user: 'moose',
          password: 'secret',
          host: 'localhost',
          database: 'moose_inventory_test'
        ).and_return(:postgresql_connection)

        @db.init_postgresql
        expect(@db.db).to eq(:postgresql_connection)
      ensure
        @db.instance_variable_set(:@db, saved_db)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
      end
    end
  end

  describe '.db' do
    it 'should be responsive' do
      expect(@db.respond_to?(:db)).to eq(true)
    end

    it 'should not be nil' do
      expect(@db.db).not_to be_nil
    end
  end

  describe '.models' do
    it 'should be responsive' do
      expect(@db.respond_to?(:models)).to eq(true)
    end

    it 'should not be nil' do
      expect(@db.models).not_to be_nil
    end
  end

  describe '.exceptions' do
    it 'should be responsive' do
      expect(@db.respond_to?(:exceptions)).to eq(true)
    end

    it 'should not be nil' do
      expect(@db.exceptions).not_to be_nil
    end
  end

  describe 'tables' do
    it 'should have a hosts table' do
      schema = @db.db.schema(:hosts)
      expect(schema).not_to be_nil
    end

    it 'should have a hostsvars table' do
      schema = @db.db.schema(:hostvars)
      expect(schema).not_to be_nil
    end
    it 'should have a groups table' do
      schema = @db.db.schema(:groups)
      expect(schema).not_to be_nil
    end

    it 'should have a groupvars table' do
      schema = @db.db.schema(:groupvars)
      expect(schema).not_to be_nil
    end

    it 'should have a groups_hosts table' do
      schema = @db.db.schema(:groups_hosts)
      expect(schema).not_to be_nil
    end
  end

  describe '.reset()' do
    it 'should be responsive' do
      result = @db.respond_to?(:reset)
      expect(result).to eq(true)
    end

    it 'should purge the database of contents' do
      # Put at least one host and one group into the database
      @db.models[:host].create(name: 'reset-host')
      @db.models[:group].create(name: 'reset-group')

      # Reset the DB
      @db.reset

      #
      hosts = @db.models[:host].all
      expect(hosts.count).to eq(0)

      group = @db.models[:group].all
      expect(group.count).to eq(0)
    end
  end

  describe '.transaction()' do
    before(:each) do
      @db.reset
    end

    it 'should be responsive' do
      result = @db.respond_to?(:transaction)
      expect(result).to eq(true)
    end

    it 'should perform transactions' do
      hosts = @db.models[:host].all
      count = { initial: hosts.count, items: 0 }

      @db.transaction  do
        # @db.transaction('should perform transactions') do
        (1..3).each do |_n|
          count[:items] = count[:items] + 1
          @db.models[:host].create(name: "transaction-#{count[:items]}")
        end
      end

      hosts = @db.models[:host].all
      count[:final] = hosts.count

      # puts "\n#{ JSON.pretty_generate(@db.debug) }"
      # puts "#{ JSON.pretty_generate(count) }"

      expect(count[:final]).to eq(count[:initial] + count[:items])
    end

    it 'should roll back failed transactions' do
      hosts = @db.models[:host].all
      count = { initial: hosts.count, items: 0 }

      @db.transaction  do
        # @db.transaction('should roll back failed transactions') do
        (1..3).each do |_n|
          count[:items] = count[:items] + 1
          @db.models[:host].create(name: "rollback-#{count[:items]}")
        end
        fail Sequel::Rollback, 'Test error' #
      end

      hosts = @db.models[:host].all
      count[:final] = hosts.count

      # puts "\n#{ JSON.pretty_generate(@db.debug) }"
      # puts "#{ JSON.pretty_generate(count) }"

      expect(count[:final]).to eq(count[:initial])
    end
  end
end
