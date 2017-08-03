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
    @cli = Moose::Inventory::Cli
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    # We make some @cli calls, which changes config,
    # so we must reset config on each pass
    @config.init(@mockargs)
    @db.reset
  end

  #==================
  describe 'listvar' do
    #-----------------
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:listvars)
      expect(result).to eq(true)
    end

    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  { @app.start(%w(host listvars)) }

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end

    #-----------------
    it '--ansible <missing args> ... should abort with an error' do
      args = @mockargs.clone
      args.concat(%w(--ansible host listvars)).flatten

      actual = runner { @cli.start(args) }

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments for Ansible mode, 0 for 1.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'HOST ... should return a list of host variables grouped by host' do
      host_name = 'test_host'
      host_vars = %w(foo=bar cow=chicken)

      tmp = runner {  @app.start(%W(host add #{host_name})) }
      tmp = runner {  @app.start(%W(host addvar #{host_name} #{host_vars[0]} #{host_vars[1]})) }

      actual = runner do
        @app.start(%W(host listvars #{host_name}))
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
      host_vars = %w(foo=bar cow=chicken)

      tmp = runner {  @app.start(%W(host add #{host_name})) }
      tmp = runner {  @app.start(%W(host addvar #{host_name} #{host_vars[0]} #{host_vars[1]})) }

      actual = runner do
        @cli.start(%W(--ansible host listvars #{host_name}))
      end

      # @console.out(actual, 'y')

      # Check output
      meta = {}
      meta['hostvars'.to_sym] = {}
      meta['hostvars'.to_sym][host_name.to_sym] = {}

      mock = {}
      host_vars.each do |hv|
        hv_array = hv.split('=')
        mock[hv_array[0].to_sym] = hv_array[1]
        meta['hostvars'.to_sym][host_name.to_sym][hv_array[0].to_sym] = hv_array[1]
      end
      mock['_meta'.to_sym] = meta

      desired = {}
      desired[:STDOUT] = mock.to_json + "\n"
      expected(actual, desired)
    end

    #------------------------
    it '--ansible HOST ... should be an alias for Ansible\'s --host HOST' do
      host_name = 'test_host'
      host_vars = %w(foo=bar cow=chicken)

      tmp = runner {  @app.start(%W(host add #{host_name})) }
      tmp = runner {  @app.start(%W(host addvar #{host_name} #{host_vars[0]} #{host_vars[1]})) }

      actual = runner do
        @cli.start(%W(--host #{host_name}))
      end

      # @console.out(actual, 'y')

      # Check output
      meta = {}
      meta['hostvars'.to_sym] = {}
      meta['hostvars'.to_sym][host_name.to_sym] = {}

      mock = {}
      host_vars.each do |hv|
        hv_array = hv.split('=')
        mock[hv_array[0].to_sym] = hv_array[1]
        meta['hostvars'.to_sym][host_name.to_sym][hv_array[0].to_sym] = hv_array[1]
      end
      mock['_meta'.to_sym] = meta

      desired = {}
      desired[:STDOUT] = mock.to_json + "\n"
      expected(actual, desired)
    end
  end
end
