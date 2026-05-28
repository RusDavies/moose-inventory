# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Group do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Group, command_ivar: :@group)
  end

  before(:each) do
    reset_cli_harness
  end

  describe 'rmvar' do
    it 'should be responsive' do
      result = @group.method_defined?(:rmvar, false)
      expect(result).to eq(true)
    end

    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w[group rmvar])
      end

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP key=value ... should abort if the group does not exist' do
      group_name = 'does-not-exist'
      var_name = 'foo=bar'
      actual = runner do
        @app.start(%W[group rmvar #{group_name} #{var_name}])
      end

      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Remove variable(s) '#{var_name}' from group '#{group_name}':\n  " \
        "- retrieve group '#{group_name}'...\n"
      desired[:STDERR] =
        "An error occurred during a transaction, any changes have been rolled back.\n" \
        "ERROR: The group '#{group_name}' does not exist.\n"
      expected(actual, desired)
    end

    #------------------------
    it '<malformed> ... should abort with an error' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var

      group_name = 'test1'
      @db.models[:group].create(name: group_name)
      cases = %w[
        =bar
        foo=bar=
        =foo=bar
        foo=bar=extra
      ]

      cases.each do |args|
        actual = runner do
          @app.start(%W[group rmvar #{group_name} #{args}])
        end
        # @console.out(actual,'p')

        desired = { aborted: true }
        desired[:STDOUT] =
          "Remove variable(s) '#{args}' from group '#{group_name}':\n  " \
          "- retrieve group '#{group_name}'...\n    " \
          "- OK\n  " \
          "- remove variable '#{args}'...\n"
        desired[:STDERR] =
          "An error occurred during a transaction, any changes have been rolled back.\n" \
          "ERROR: Incorrect format in {#{args}}. Expected 'key' or 'key=value'.\n"

        expected(actual, desired)
      end
    end

    #------------------------
    it 'GROUP key --dry-run should not remove the group variable' do
      group_name = 'group_test'
      @db.models[:group].create(name: group_name)
      runner { @app.start(%W[group addvar #{group_name} var1=val1]) }

      actual = runner { @app.start(%W[group rmvar #{group_name} var1 --dry-run]) }

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDOUT]).to include('Dry run complete. No changes applied.')
      group = @db.models[:group].find(name: group_name)
      expect(group.groupvars_dataset[name: 'var1']).not_to be_nil
    end

    #------------------------
    it 'GROUP <valid args> ... should remove the group variable' do
      group_name = 'group_test'
      var = { name: 'foo', value: 'bar' }
      cases = %W[
        #{var[:name]}
        #{var[:name]}=
        #{var[:name]}=#{var[:value]}
      ]
      cases.each do |example|
        # reset the db
        @db.reset

        # Add an initial group and groupvar
        @db.models[:group].create(name: group_name)
        runner do
          @app.start(%W[group addvar #{group_name} #{var[:name]}=#{var[:value]}])
        end

        # Try to remove the groupvar using the case example valid args
        actual = runner do
          @app.start(%W[group rmvar #{group_name} #{example}])
        end
        # @console.out(actual,'p')

        # Check the output
        desired = { aborted: false }
        desired[:STDOUT] =
          "Remove variable(s) '#{example}' from group '#{group_name}':\n  " \
          "- retrieve group '#{group_name}'...\n    " \
          "- OK\n  " \
          "- remove variable '#{example}'...\n    " \
          "- OK\n  " \
          "- all OK\n" \
          "Succeeded.\n"

        # @console.out(desired,'p')
        expected(actual, desired)

        # Check the db
        group = @db.models[:group].find(name: group_name)
        groupvars = group.groupvars_dataset
        expect(groupvars.count).to eq(0)

        groupvars = @db.models[:groupvar].all
        expect(groupvars.count).to eq(0)
      end
    end

    #------------------------
    it 'GROUP key1=value1 key2=value2 ... should remove multiple key/value pairs' do
      group_name = 'test_group'
      varsarray  = [
        { name: 'var1', value: 'val1' },
        { name: 'var2', value: 'val2' }
      ]

      vars = varsarray.map do |var|
        "#{var[:name]}=#{var[:value]}"
      end

      @db.models[:group].create(name: group_name)
      runner do
        @app.start(%W[group addvar #{group_name}] + vars)
      end

      actual = runner do
        @app.start(%W[group rmvar #{group_name}] + vars)
      end
      # @console.out(actual,'y')

      desired = { aborted: false }
      desired[:STDOUT] =
        "Remove variable(s) '#{vars.join(',')}' from group '#{group_name}':\n  " \
        "- retrieve group '#{group_name}'...\n    " \
        "- OK\n"
      vars.each do |var|
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - remove variable '#{var}'...\n    " \
                           "- OK\n"
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - all OK\n" \
                         "Succeeded.\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      group = @db.models[:group].find(name: group_name)
      groupvars = group.groupvars_dataset
      expect(groupvars.count).to eq(0)
    end
  end
end
# rubocop:enable Metrics/BlockLength
