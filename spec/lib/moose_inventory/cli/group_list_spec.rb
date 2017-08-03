require 'spec_helper'

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
    @cli = Moose::Inventory::Cli
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #====================
  describe 'list' do
    #---------------------
    it 'should be responsive' do
      result = @group.instance_methods(false).include?(:list)
      expect(result).to eq(true)
    end

    #---------------------
    it 'should return an empty set when no results' do
      # no items in the db
      actual = runner { @app.start(%w(group list)) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should get a list of group from the db' do
      var = 'foo=bar'
      host_name = 'test_host'

      mock = {}
      groups = %w(group1 group2 group3)
      groups.each do |name|
        runner { @app.start(%W(group add #{name})) }
        runner { @app.start(%W(group addvar #{name} #{var})) }
        mock[name.to_sym] = {}
        mock[name.to_sym][:groupvars] = { foo: 'bar' }
      end

      # items should now be in the db
      actual = runner { @app.start(%w(group list)) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should be an alias of --list (i.e. Ansible parameter)' do
      host_name = 'test_host'

      mock = {}
      groups = %w(group1 group2 group3)
      groups.each do |name|
        runner { @app.start(%W(group add #{name})) }
        mock[name.to_sym] = {}
      end

      args = @mockargs.clone
      args << '--list'

      actual = runner { @cli.start(args) }

      # @console.out(actual, 'y')

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_json + "\n"

      expected(actual, desired)
    end
    end
  end

