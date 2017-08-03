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

  describe 'rmvar' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:rmvar)
      expect(result).to eq(true)
    end

    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w(host rmvar)) # <- no group given
      end

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'HOST key=value ... should abort if the host does not exist' do
      host_name = 'not-a-host'
      var_name = 'foo=bar'
      actual = runner do
        @app.start(%W(host rmvar #{host_name} #{var_name}))
      end

      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Remove variable(s) '#{var_name}' from host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"
      desired[:STDERR] =
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The host '#{host_name}' does not exist.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'HOST <malformed> ... should abort with an error' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'
      @db.models[:host].create(name: host_name)

      var = { name: 'foo', value: 'bar' }
      cases = %w(
        =bar
        foo=bar=
        =foo=bar
        foo=bar=extra
      )

      cases.each do |args|
        actual = runner do
          @app.start(%W(host rmvar #{host_name} #{args}))
        end
        # @console.out(actual,'p')

        desired = { aborted: true }
        desired[:STDOUT] =
          "Remove variable(s) '#{args}' from host '#{host_name}':\n"\
          "  - retrieve host '#{host_name}'...\n"\
          "    - OK\n"\
          "  - remove variable '#{args}'...\n"
        desired[:STDERR] =
          "An error occurred during a transaction, any changes have been rolled back.\n"\
          "ERROR: Incorrect format in {#{args}}. Expected 'key' or 'key=value'.\n"

        expected(actual, desired)
      end
    end

    #------------------------
    it 'host rmvar HOST <valid args> ... should remove the host variable' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      host_name = 'test1'

      var = { name: 'foo', value: 'bar' }
      cases = %W(
        #{var[:name]}
        #{var[:name]}=
        #{var[:name]}=#{var[:value]}
      )
      cases.each do |example|
        # reset the db
        @db.reset

        # Add an initial host and hostvar
        @db.models[:host].create(name: host_name)
        runner do
          @app.start(%W(host addvar #{host_name} #{var[:name]}=#{var[:value]}))
        end

        # Try to remove the hostvar using the case example valid args
        actual = runner do
          @app.start(%W(host rmvar #{host_name} #{example}))
        end
        # @console.out(actual,'p')

        # Check the output
        desired = { aborted: false }
        desired[:STDOUT] =
          "Remove variable(s) '#{example}' from host '#{host_name}':\n"\
          "  - retrieve host '#{host_name}'...\n"\
          "    - OK\n"\
          "  - remove variable '#{example}'...\n"\
          "    - OK\n"\
          "  - all OK\n"\
          "Succeeded.\n"

        # @console.out(desired,'p')
        expected(actual, desired)

        # Check the db
        host = @db.models[:host].find(name: host_name)
        hostvars = host.hostvars_dataset
        expect(hostvars.count).to eq(0)

        hostvars = @db.models[:hostvar].all
        expect(hostvars.count).to eq(0)
      end
    end

    #------------------------
    it 'HOST key1=value1 key2=value2 ... should remove multiple key/value pairs' do
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

      actual = runner do
        @app.start(%W(host rmvar #{host_name}) + vars)
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Remove variable(s) '#{vars.join(',')}' from host '#{host_name}':\n"\
        "  - retrieve host '#{host_name}'...\n"\
        "    - OK\n"
      vars.each do |var|
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - remove variable '#{var}'...\n"\
                           "    - OK\n"
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - all OK\n"\
                         "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: host_name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(0)
    end
  end
end
