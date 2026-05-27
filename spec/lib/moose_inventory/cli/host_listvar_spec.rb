# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Host, command_ivar: :@host, include_cli: true)
  end

  before(:each) do
    reset_cli_harness(reset_config: true)
  end

  #==================
  describe 'listvar' do
    #-----------------
    it 'should be responsive' do
      result = @host.method_defined?(:listvars, false)
      expect(result).to eq(true)
    end

    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  { @app.start(%w[host listvars]) }

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end

    #-----------------
    it '--ansible <missing args> ... should abort with an error' do
      args = @mockargs.clone
      args.push('--ansible', 'host', 'listvars').flatten

      actual = runner { @cli.start(args) }

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments for Ansible mode, 0 for 1.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'HOST ... should return a list of host variables grouped by host' do
      host_name = 'test_host'
      host_vars = %w[foo=bar cow=chicken]

      runner {  @app.start(%W[host add #{host_name}]) }
      runner {  @app.start(%W[host addvar #{host_name} #{host_vars[0]} #{host_vars[1]}]) }

      actual = runner do
        @app.start(%W[host listvars #{host_name}])
      end

      # @console.out(actual, 'y')

      # Check output
      mock = {}
      mock[host_name.to_sym] = {}
      host_vars.each do |hv|
        hv_array = hv.split('=')
        mock[host_name.to_sym][hv_array[0].to_sym] = hv_array[1]
      end

      desired = {}
      desired[:STDOUT] = mock.to_yaml
      expected(actual, desired)
    end

    #------------------------
    it '--ansible HOST ... should return a list of host variables per Ansible specs' do
      host_name = 'test_host'
      host_vars = %w[foo=bar cow=chicken]

      runner {  @app.start(%W[host add #{host_name}]) }
      runner {  @app.start(%W[host addvar #{host_name} #{host_vars[0]} #{host_vars[1]}]) }

      actual = runner do
        @cli.start(%W[--config #{@mockarg_parts[:config]} --ansible host listvars #{host_name}])
      end

      # @console.out(actual, 'y')

      # Check output
      meta = {}
      meta[:hostvars] = {}
      meta[:hostvars][host_name.to_sym] = {}

      mock = {}
      host_vars.each do |hv|
        hv_array = hv.split('=')
        mock[hv_array[0].to_sym] = hv_array[1]
        meta[:hostvars][host_name.to_sym][hv_array[0].to_sym] = hv_array[1]
      end
      mock[:_meta] = meta

      desired = {}
      desired[:STDOUT] = "#{mock.to_json}\n"
      expected(actual, desired)
    end

    #------------------------
    it '--ansible HOST ... should be an alias for Ansible\'s --host HOST' do
      host_name = 'test_host'
      host_vars = %w[foo=bar cow=chicken]

      runner {  @app.start(%W[host add #{host_name}]) }
      runner {  @app.start(%W[host addvar #{host_name} #{host_vars[0]} #{host_vars[1]}]) }

      actual = runner do
        @cli.start(%W[--config #{@mockarg_parts[:config]} --host #{host_name}])
      end

      # @console.out(actual, 'y')

      # Check output
      meta = {}
      meta[:hostvars] = {}
      meta[:hostvars][host_name.to_sym] = {}

      mock = {}
      host_vars.each do |hv|
        hv_array = hv.split('=')
        mock[hv_array[0].to_sym] = hv_array[1]
        meta[:hostvars][host_name.to_sym][hv_array[0].to_sym] = hv_array[1]
      end
      mock[:_meta] = meta

      desired = {}
      desired[:STDOUT] = "#{mock.to_json}\n"
      expected(actual, desired)
    end
  end
end
# rubocop:enable Metrics/BlockLength
