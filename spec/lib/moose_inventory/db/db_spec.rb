require 'spec_helper'

RSpec.describe 'Moose::Inventory::DB' do
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
