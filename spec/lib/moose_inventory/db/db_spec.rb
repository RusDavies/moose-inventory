# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'Moose::Inventory::DB' do
  def with_db_config(db_config)
    saved_db = @db.instance_variable_get(:@db)
    saved_models = @db.instance_variable_get(:@models)
    saved_exceptions = @db.instance_variable_get(:@exceptions)
    saved_settings = @config._settings.dup

    begin
      @db.reset_runtime_state
      @db.init_exceptions
      @config._settings.clear
      @config._settings[:config] = { db: db_config }
      yield
    ensure
      current_db = @db.instance_variable_get(:@db)
      current_db.disconnect if current_db.respond_to?(:disconnect)
      @db.reset_runtime_state
      @db.instance_variable_set(:@db, saved_db)
      @db.instance_variable_set(:@models, saved_models)
      @db.instance_variable_set(:@exceptions, saved_exceptions)
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
      config: File.join(spec_root, 'config/config.yml'),
      format: 'yaml',
      env: 'test'
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
      with_db_config(adapter: 'unsupported') do
        expect { @db.init }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /database adapter unsupported is not yet supported/
        )
        expect(@db.exceptions[:moose]).to eq(Moose::Inventory::DB::MooseDBException)
      end
    end
  end

  describe '.init_exceptions()' do
    it 'is responsive' do
      expect(@db.respond_to?(:init_exceptions)).to eq(true)
    end
  end

  describe '.reset_runtime_state()' do
    it 'clears cached db, models, and exceptions' do
      saved_db = @db.instance_variable_get(:@db)
      saved_models = @db.instance_variable_get(:@models)
      saved_exceptions = @db.instance_variable_get(:@exceptions)

      @db.instance_variable_set(:@db, :fake_db)
      @db.instance_variable_set(:@models, { fake: true })
      @db.instance_variable_set(:@exceptions, { fake: true })

      @db.reset_runtime_state

      expect(@db.db).to be_nil
      expect(@db.models).to be_nil
      expect(@db.exceptions).to be_nil

      @db.instance_variable_set(:@db, saved_db)
      @db.instance_variable_set(:@models, saved_models)
      @db.instance_variable_set(:@exceptions, saved_exceptions)
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
      saved_models = @db.instance_variable_get(:@models)
      saved_exceptions = @db.instance_variable_get(:@exceptions)
      saved_settings = @config._settings.dup
      tmpdir = Dir.mktmpdir('moose-inventory-sqlite')
      nested_dbfile = File.join(tmpdir, 'one', 'two', 'inventory.db')

      begin
        @db.reset_runtime_state
        @config._settings.clear
        @config._settings[:config] = {
          db: {
            adapter: 'sqlite3',
            file: nested_dbfile
          }
        }

        @db.init_sqlite3

        expect(File.directory?(File.dirname(nested_dbfile))).to eq(true)
        expect(File.file?(nested_dbfile)).to eq(true)
      ensure
        current_db = @db.instance_variable_get(:@db)
        current_db.disconnect if current_db.respond_to?(:disconnect)
        @db.reset_runtime_state
        @db.instance_variable_set(:@db, saved_db)
        @db.instance_variable_set(:@models, saved_models)
        @db.instance_variable_set(:@exceptions, saved_exceptions)
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

    it 'raises a Moose DB exception when password and password_env are missing' do
      with_db_config(
        adapter: 'mysql',
        host: 'localhost',
        database: 'moose_inventory_test',
        user: 'moose'
      ) do
        expect { @db.init_mysql }.to raise_error(
          Moose::Inventory::DB::MooseDBException,
          /Expected key password or password_env missing in mysql configuration/
        )
      end
    end

    it 'uses a mysql password from the configured environment variable' do
      saved_db = @db.instance_variable_get(:@db)
      saved_settings = @config._settings.dup
      saved_password = ENV.fetch('MOOSE_INVENTORY_MYSQL_PASSWORD', nil)
      mysql_config = {
        adapter: 'mysql',
        host: 'localhost',
        database: 'moose_inventory_test',
        user: 'moose',
        password_env: 'MOOSE_INVENTORY_MYSQL_PASSWORD'
      }

      begin
        ENV['MOOSE_INVENTORY_MYSQL_PASSWORD'] = 'env-secret'
        @db.instance_variable_set(:@db, nil)
        @config._settings.clear
        @config._settings[:config] = { db: mysql_config }

        expect(Sequel).to receive(:mysql2).with(
          user: 'moose',
          password: 'env-secret',
          host: 'localhost',
          database: 'moose_inventory_test'
        ).and_return(:mysql2_connection)

        @db.init_mysql
        expect(@db.db).to eq(:mysql2_connection)
      ensure
        if saved_password.nil?
          ENV.delete('MOOSE_INVENTORY_MYSQL_PASSWORD')
        else
          ENV['MOOSE_INVENTORY_MYSQL_PASSWORD'] = saved_password
        end
        @db.instance_variable_set(:@db, saved_db)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
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
        password: 'secret'
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

    it 'raises a Moose DB exception when password_env points to an unset variable' do
      saved_password = ENV.fetch('MOOSE_INVENTORY_POSTGRES_PASSWORD', nil)
      ENV.delete('MOOSE_INVENTORY_POSTGRES_PASSWORD')

      begin
        with_db_config(
          adapter: 'postgresql',
          host: 'localhost',
          database: 'moose_inventory_test',
          user: 'moose',
          password_env: 'MOOSE_INVENTORY_POSTGRES_PASSWORD'
        ) do
          expect { @db.init_postgresql }.to raise_error(
            Moose::Inventory::DB::MooseDBException,
            /Environment variable MOOSE_INVENTORY_POSTGRES_PASSWORD is not set for postgresql password/
          )
        end
      ensure
        ENV['MOOSE_INVENTORY_POSTGRES_PASSWORD'] = saved_password unless saved_password.nil?
      end
    end

    it 'uses a postgresql password from the configured environment variable' do
      saved_db = @db.instance_variable_get(:@db)
      saved_settings = @config._settings.dup
      saved_password = ENV.fetch('MOOSE_INVENTORY_POSTGRES_PASSWORD', nil)
      postgresql_config = {
        adapter: 'postgresql',
        host: 'localhost',
        database: 'moose_inventory_test',
        user: 'moose',
        password_env: 'MOOSE_INVENTORY_POSTGRES_PASSWORD'
      }

      begin
        ENV['MOOSE_INVENTORY_POSTGRES_PASSWORD'] = 'env-secret'
        @db.instance_variable_set(:@db, nil)
        @config._settings.clear
        @config._settings[:config] = { db: postgresql_config }

        expect(Sequel).to receive(:postgres).with(
          user: 'moose',
          password: 'env-secret',
          host: 'localhost',
          database: 'moose_inventory_test'
        ).and_return(:postgresql_connection)

        @db.init_postgresql
        expect(@db.db).to eq(:postgresql_connection)
      ensure
        if saved_password.nil?
          ENV.delete('MOOSE_INVENTORY_POSTGRES_PASSWORD')
        else
          ENV['MOOSE_INVENTORY_POSTGRES_PASSWORD'] = saved_password
        end
        @db.instance_variable_set(:@db, saved_db)
        @config._settings.clear
        @config._settings.merge!(saved_settings)
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
        password: 'secret'
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

  describe '.busy_retry_delay()' do
    it 'uses deterministic capped exponential backoff delays' do
      expect(@db.busy_retry_delay(1)).to eq(0.05)
      expect(@db.busy_retry_delay(2)).to eq(0.1)
      expect(@db.busy_retry_delay(5)).to eq(0.8)
      expect(@db.busy_retry_delay(6)).to eq(1.0)
      expect(@db.busy_retry_delay(10)).to eq(1.0)
    end
  end

  describe '.busy_database_error?()' do
    it 'identifies Sequel busy database errors by message' do
      expect(@db.busy_database_error?(Sequel::DatabaseError.new('BusyException: locked'))).to eq(true)
      expect(@db.busy_database_error?(Sequel::DatabaseError.new('other database failure'))).to eq(false)
    end
  end

  describe '.retry_busy_transaction()' do
    it 'sleeps for the deterministic retry delay before another busy retry' do
      delays = []
      error = Sequel::DatabaseError.new('BusyException: database is locked')

      @db.retry_busy_transaction(error, 3, sleeper: ->(delay) { delays << delay })

      expect(delays).to eq([0.2])
    end

    it 'raises the original error when the retry limit is exceeded' do
      error = Sequel::DatabaseError.new('BusyException: database is locked')

      actual_stderr = capture(:STDERR) do
        expect { @db.retry_busy_transaction(error, 11, sleeper: ->(_delay) {}) }
          .to raise_error(error)
      end

      expect(actual_stderr).to include('The database appears to be locked by another process')
    end
  end

  describe '.purge()' do
    it 'uses drop_table for non-sqlite adapters' do
      saved_db = @db.instance_variable_get(:@db)

      begin
        fake_db = instance_double('DB')
        @db.instance_variable_set(:@db, fake_db)
        allow(@db).to receive(:sqlite_adapter?).and_return(false)
        expect(fake_db).to receive(:drop_table).with(
          :hosts,
          :hostvars,
          :groups,
          :groupvars,
          :group_hosts,
          if_exists: true,
          cascade: true
        )

        @db.purge
      ensure
        @db.instance_variable_set(:@db, saved_db)
      end
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

    it 'retries busy database transactions before succeeding' do
      saved_db = @db.instance_variable_get(:@db)
      fake_db = Class.new do
        attr_reader :attempts

        def initialize(error)
          @error = error
          @attempts = 0
        end

        def transaction(savepoint:)
          raise ArgumentError, 'expected savepoint' unless savepoint

          @attempts += 1
          raise @error if @attempts == 1

          yield
        end
      end.new(Sequel::DatabaseError.new('BusyException: database is locked'))

      begin
        @db.instance_variable_set(:@db, fake_db)
        allow(@db).to receive(:retry_busy_transaction)

        result = @db.transaction { :ok }

        expect(result).to eq(:ok)
        expect(fake_db.attempts).to eq(2)
        expect(@db).to have_received(:retry_busy_transaction).once
      ensure
        @db.instance_variable_set(:@db, saved_db)
      end
    end

    it 're-raises non-busy database errors without retrying' do
      saved_db = @db.instance_variable_get(:@db)
      error = Sequel::DatabaseError.new('constraint failed')
      fake_db = instance_double('DB')

      begin
        @db.instance_variable_set(:@db, fake_db)
        allow(fake_db).to receive(:transaction).and_raise(error)
        allow(@db).to receive(:retry_busy_transaction)

        expect { @db.transaction { :ignored } }.to raise_error(error)
        expect(@db).not_to have_received(:retry_busy_transaction)
      ensure
        @db.instance_variable_set(:@db, saved_db)
      end
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
        raise Sequel::Rollback, 'Test error'
      end

      hosts = @db.models[:host].all
      count[:final] = hosts.count

      # puts "\n#{ JSON.pretty_generate(@db.debug) }"
      # puts "#{ JSON.pretty_generate(count) }"

      expect(count[:final]).to eq(count[:initial])
    end

    it 'prints concise Moose DB transaction errors by default' do
      saved_trace = @config._confopts[:trace]
      @config._confopts[:trace] = false

      begin
        actual = runner do
          @db.transaction do
            raise @db.exceptions[:moose], 'Trace regression target'
          end
        end
      ensure
        @config._confopts[:trace] = saved_trace
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to eq(
        "An error occurred during a transaction, any changes have been rolled back.\n" \
        "ERROR: Trace regression target\n"
      )
    end

    it 'prints the Moose DB exception backtrace when trace is enabled' do
      saved_trace = @config._confopts[:trace]
      @config._confopts[:trace] = true

      begin
        actual = runner do
          @db.transaction do
            raise @db.exceptions[:moose], 'Trace regression target'
          end
        end
      ensure
        @config._confopts[:trace] = saved_trace
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to include(
        "An error occurred during a transaction, any changes have been rolled back.\n"
      )
      expect(actual[:STDERR]).to include('Moose::Inventory::DB::MooseDBException')
      expect(actual[:STDERR]).to include('Trace regression target')
      expect(actual[:STDERR]).to include('spec/lib/moose_inventory/db/db_spec.rb')
      expect(actual[:STDERR]).to include("ERROR: Trace regression target\n")
      expect(actual[:STDERR]).not_to include('NoMethodError')
    end

    it 'warns and re-raises ordinary StandardError failures' do
      actual = runner do
        @db.transaction do
          raise 'generic failure'
        end
      end

      expect(actual[:aborted]).to eq(false)
      expect(actual[:unexpected].class).to eq(RuntimeError)
      expect(actual[:unexpected].message).to eq('generic failure')
      expect(actual[:STDERR]).to eq(
        "An error occurred during a transaction, any changes have been rolled back.\n"
      )
    end

    it 'warns and re-raises SystemExit failures triggered inside the transaction' do
      actual = runner do
        @db.transaction do
          raise SystemExit.new(7), 'stop now'
        end
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to eq(
        "An error occurred during a transaction, any changes have been rolled back.\n"
      )
    end

    it 'does not swallow non-rescued fatal exceptions such as interrupts' do
      expect do
        @db.transaction do
          raise Interrupt, 'ctrl-c'
        end
      end.to raise_error(Interrupt, 'ctrl-c')
    end
  end
end
