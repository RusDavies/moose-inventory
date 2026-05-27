# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Host, command_ivar: :@host)
  end

  before(:each) do
    reset_cli_harness
  end

  #=======================
  describe 'get' do
    #---------------------
    it 'Host.get() should be responsive' do
      result = @host.method_defined?(:get, false)
      expect(result).to eq(true)
    end

    #---------------------
    it 'host get <missing args> ... should abort with an error' do
      # no items in the db
      actual = runner { @app.start(%w[host get]) }

      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more\n"

      expected(actual, desired)
    end

    #---------------------
    it 'host get HOST ... should return an empty set when HOST doesn\'t exist' do
      # no items in the db
      name = 'not-in-db'
      actual = runner { @app.start(%W[host get #{name}]) }

      desired = {}
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'host get HOST ... should get a host from the db' do
      name = 'test-host-add'
      runner { @app.start(%W[host add #{name}]) }

      actual = runner { @app.start(%W[host get #{name}]) }

      mock = {}
      mock[name.to_sym] = {}
      mock[name.to_sym][:groups] = ['ungrouped']

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'host get HOST ... should display hostvars, if any are set' do
      name = 'test-host-add'
      var = 'foo=bar'
      runner { @app.start(%W[host add #{name}]) }
      runner { @app.start(%W[host addvar #{name} #{var}]) }

      actual = runner { @app.start(%W[host get #{name}]) }

      mock = {}
      mock[name.to_sym] = {}
      mock[name.to_sym][:groups] = ['ungrouped']
      mock[name.to_sym][:hostvars] = { foo: 'bar' }

      desired = {}
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end
  end
end
# rubocop:enable Metrics/BlockLength
