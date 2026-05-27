# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

RSpec.describe Moose::Inventory::Cli::Group do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Group, command_ivar: :@group, include_cli: true)
  end

  before(:each) do
    reset_cli_harness
  end

  #====================
  describe 'list' do
    #---------------------
    it 'should be responsive' do
      result = @group.method_defined?(:list, false)
      expect(result).to eq(true)
    end

    #---------------------
    it 'should return an empty set when no results' do
      # no items in the db
      actual = runner { @app.start(%w[group list]) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should get a list of group from the db' do
      var = 'foo=bar'

      mock = {}
      groups = %w[group1 group2 group3]
      groups.each do |name|
        runner { @app.start(%W[group add #{name}]) }
        runner { @app.start(%W[group addvar #{name} #{var}]) }
        mock[name.to_sym] = {}
        mock[name.to_sym][:groupvars] = { foo: 'bar' }
      end

      # items should now be in the db
      actual = runner { @app.start(%w[group list]) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should be an alias of --list (i.e. Ansible parameter)' do
      mock = {}
      groups = %w[group1 group2 group3]
      groups.each do |name|
        runner { @app.start(%W[group add #{name}]) }
        mock[name.to_sym] = { hosts: [] }
      end

      args = @mockargs.clone
      args << '--list'

      actual = runner { @cli.start(args) }

      # @console.out(actual, 'y')

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = "#{mock.to_json}\n"

      expected(actual, desired)
    end
  end
end
# rubocop:enable Metrics/BlockLength
