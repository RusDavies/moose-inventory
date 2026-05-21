require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Group do
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
    @group = Moose::Inventory::Cli::Group
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #==================
  describe 'addvar' do
    #-----------------
    it 'should be responsive' do
      result = @group.instance_methods(false).include?(:addvar)
      expect(result).to eq(true)
    end

    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w(group addvar)) # <- no group given
      end
      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP key=value ... should abort if the group does not exist' do
      group_name = 'not-a-group'
      group_var = 'foo=bar'

      actual = runner do
        @app.start(%W(group addvar #{group_name} #{group_var}))
      end

      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Add variables '#{group_var}' to group '#{group_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"
      desired[:STDERR] =
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The group '#{group_name}' does not exist.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP <malformed> ... should abort with an error' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      group_name = 'test_group'
      @db.models[:group].create(name: group_name)

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
          @app.start(%W(group addvar #{group_name} #{args}))
        end
        # @console.out(actual,'p')

        desired = { aborted: true }
        desired[:STDOUT] =
          "Add variables '#{args}' to group '#{group_name}':\n"\
          "  - retrieve group '#{group_name}'...\n"\
          "    - OK\n"\
          "  - add variable '#{args}'...\n"

        desired[:STDERR] =
          "An error occurred during a transaction, any changes have been rolled back.\n"\
          "ERROR: Incorrect format in '{#{args}}'. Expected 'key=value'.\n"

        expected(actual, desired)
      end
    end

    #------------------------
    it 'GROUP key=value ... should associate the group with the key/value pair' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      group_name = 'test1'
      var = { name: 'var1', value: 'testval' }

      @db.models[:group].create(name: group_name)

      actual = runner do
        @app.start(%W(group addvar #{group_name} #{var[:name]}=#{var[:value]}))
      end
      # @console.out(actual,'p')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{var[:name]}=#{var[:value]}' to group '#{group_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"\
        "  - add variable '#{var[:name]}=#{var[:value]}'...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      group = @db.models[:group].find(name: group_name)
      groupvars = group.groupvars_dataset
      expect(groupvars.count).to eq(1)
      expect(groupvars[name: var[:name]]).not_to be_nil
      expect(groupvars[name: var[:name]][:value]).to eq(var[:value])
    end

    #------------------------
    it 'GROUP key1=value1 key2=value2 ... should associate the group with multiple key/value pairs' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      group_name = 'test1'
      varsarray  = [
        { name: 'var1', value: 'val1' },
        { name: 'var2', value: 'val2' },
      ]

      vars = []
      varsarray.each do |var|
        vars << "#{var[:name]}=#{var[:value]}"
      end

      @db.models[:group].create(name: group_name)

      actual = runner do
        @app.start(%W(group addvar #{group_name}) + vars)
      end

      # @console.out(actual,'y')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{vars.join(',')}' to group '#{group_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
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
      group = @db.models[:group].find(name: group_name)
      groupvars = group.groupvars_dataset
      expect(vars.count).to eq(vars.length)
    end

    #------------------------
    it 'GROUP key=value ... should update an already existing association' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      group_name = 'test1'
      var = { name: 'var1', value: 'testval' }

      @db.models[:group].create(name: group_name)
      runner { @app.start(%W(group addvar #{group_name} #{var[:name]}=#{var[:value]})) }

      var[:value] = 'newtestval'
      actual = runner do
        @app.start(%W(group addvar #{group_name} #{var[:name]}=#{var[:value]}))
      end
      # @console.out(actual,'y')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Add variables '#{var[:name]}=#{var[:value]}' to group '#{group_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"\
        "  - add variable '#{var[:name]}=#{var[:value]}'...\n"\
        "    - already exists, applying as an update...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      group = @db.models[:group].find(name: group_name)
      groupvars = group.groupvars_dataset
      expect(groupvars.count).to eq(1)
      expect(groupvars[name: var[:name]]).not_to be_nil
      expect(groupvars[name: var[:name]][:value]).to eq(var[:value])

      groupvars = @db.models[:groupvar].all
      expect(groupvars.count).to eq(1)
    end
  end
end
