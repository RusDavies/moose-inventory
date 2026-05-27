# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Host, command_ivar: :@host)
  end

  before(:each) do
    reset_cli_harness
  end

  #====================
  describe 'list' do
    #---------------------
    it 'should be responsive' do
      result = @host.method_defined?(:list, false)
      expect(result).to eq(true)
    end

    #---------------------
    it 'should return an empty set when no results' do
      # no items in the db
      actual = runner { @app.start(%w[host list]) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should get a list of hosts from the db' do
      mock = {}
      hosts = %w[host1 host2 host3]
      hosts.each do |name|
        runner { @app.start(%W[host add #{name}]) }
        runner { @app.start(%W[host addvar #{name} foo=bar]) }
        mock[name.to_sym] = {}
        mock[name.to_sym][:groups] = ['ungrouped']
        mock[name.to_sym][:hostvars] = { foo: 'bar' }
      end

      # items should now be in the db
      actual = runner { @app.start(%w[host list]) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end
  end
end
# rubocop:enable Metrics/BlockLength
