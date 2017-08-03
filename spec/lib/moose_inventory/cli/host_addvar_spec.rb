require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
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
    @db.init if @db.db.nil?

    @console = Moose::Inventory::Cli::Formatter
    @host = Moose::Inventory::Cli::Host
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #==================
  describe 'addvar' do
    #-----------------
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:addvar)
      expect(result).to eq(true)
    end

    #-----------------
    it 'host addvar <missing args> ... should abort with an error' do
      actual = runner do
        @app.start(%w(host addvar)) # <- no group given
      end

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host addvar HOST key=value ... should abort if the host does not exist' do
      host_name = 'not-a-host'
      host_var = 'foo=bar'

      actual = runner do
        @app.start(%W(host addvar #{host_name} #{host_var}))
      end

      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Add variables '#{host_var}' to host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"
      desired[:STDERR] =
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The host '#{host_name}' does not exist.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host addvar HOST <malformed> ... should abort with an error' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      @db.models[:host].create(name: host_name)

      var = { name: 'var1', value: 'testval' }
      cases = %w(
        testvar
        testvar=
        =testval
        testvar=testval=
        =testvar=testval
        testvar=testval=extra
      )

      cases.each do |args|
        actual = runner do
          @app.start(%W(host addvar #{host_name} #{args}))
        end
        # @console.out(actual,'p')

        desired = { aborted: true }
        desired[:STDOUT] =
          "Add variables '#{args}' to host '#{host_name}':\n"\
          "  - retrieve host '#{host_name}'...\n"\
          "    - OK\n"\
          "  - add variable '#{args}'...\n"

        desired[:STDERR] =
          "An error occurred during a transaction, any changes have been rolled back.\n"\
          "ERROR: Incorrect format in '{#{args}}'. Expected 'key=value'.\n"

        expected(actual, desired)
      end
    end

    #------------------------
    fit 'host addvar HOST key=value ... should associate the host with the key/value pair' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      var = { name: 'var1', value: 'testval' }

      @db.models[:host].create(name: host_name)

      actual = runner do
        @app.start(%W(host addvar #{host_name} #{var[:name]}=#{var[:value]}))
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{var[:name]}=#{var[:value]}' to host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"\
        "    - OK\n"\
        "  - add variable '#{var[:name]}=#{var[:value]}'...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: host_name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(1)
      expect(hostvars[name: var[:name]]).not_to be_nil
      expect(hostvars[name: var[:name]][:value]).to eq(var[:value])
    end

    #------------------------
    fit 'host addvar HOST "my val"="hello world" ... should associate the host with the key/value pair' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      var = { name: 'my val', value: 'hello world' }

      @db.models[:host].create(name: host_name)

      actual = runner do
        @app.start(%W(host addvar #{host_name} #{var[:name]}=#{var[:value]}))
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{var[:name]}=#{var[:value]}' to host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"\
        "    - OK\n"\
        "  - add variable '#{var[:name]}=#{var[:value]}'...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: host_name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(1)
      expect(hostvars[name: var[:name]]).not_to be_nil
      expect(hostvars[name: var[:name]][:value]).to eq(var[:value])
    end

    #------------------------
    it 'host addvar HOST key1=value1 key2=value2 ... should associate the host with multiple key/value pairs' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      varsarray = [
        { name: 'var1', value: 'val1' },
        { name: 'var2', value: 'val2' },
      ]

      vars = []
      varsarray.each do |var|
        vars << "#{var[:name]}=#{var[:value]}"
      end

      @db.models[:host].create(name: host_name)

      actual = runner do
        @app.start(%W(host addvar #{host_name}) + vars)
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{vars.join(',')}' to host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"\
        "    - OK\n"
      vars.each do |var|
        desired[:STDOUT] =  desired[:STDOUT] +
                            "  - add variable '#{var}'...\n"\
                            "    - OK\n"
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - all OK\n"\
                         "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: host_name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(vars.length)
    end

    #------------------------
    it 'host addvar HOST key=value ... should update an already existing association' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      var = { name: 'var1', value: 'testval' }

      @db.models[:host].create(name: host_name)
      runner { @app.start(%W(host addvar #{host_name} #{var[:name]}=#{var[:value]})) }

      var[:value] = 'newtestval'
      actual = runner do
        @app.start(%W(host addvar #{host_name} #{var[:name]}=#{var[:value]}))
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{var[:name]}=#{var[:value]}' to host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"\
        "    - OK\n"\
        "  - add variable '#{var[:name]}=#{var[:value]}'...\n"\
        "    - already exists, applying as an update...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: host_name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(1)
      expect(hostvars[name: var[:name]]).not_to be_nil
      expect(hostvars[name: var[:name]][:value]).to eq(var[:value])

      hostvars = @db.models[:hostvar].all
      expect(hostvars.count).to eq(1)
    end
  end
end
