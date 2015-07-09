require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join(spec_root, 'config/config.yml'),
      format:  'yaml',
      env:     'test'
    }

    @mockargs = []
    @mockarg_parts.each do |key, val|
      @mockargs << "--#{key}"
      @mockargs << val
    end

    @config = Moose::Inventory::Config
    @config.init(@mockargs)
    @console = Moose::Inventory::Cli::Formatter
    
    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @host = Moose::Inventory::Cli::Host
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #=======================
  describe 'get' do
    #---------------------
    it 'Host.get() should be responsive' do
      result = @host.instance_methods(false).include?(:get)
      expect(result).to eq(true)
    end

    #---------------------
    it 'host get <missing args> ... should abort with an error' do
      # no items in the db
      name = 'not-in-db'
      actual = runner { @app.start(%W(host get)) }

      desired = {aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more\n"

      expected(actual, desired)
    end
    
    #---------------------
    it 'host get HOST ... should return an empty set when HOST doesn\'t exist' do
      # no items in the db
      name = 'not-in-db'
      actual = runner { @app.start(%W(host get #{ name })) }

      desired = {}
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'host get HOST ... should get a host from the db' do
      name = 'test-host-add'
      runner { @app.start(%W(host add #{ name })) }

      actual = runner { @app.start(%W(host get #{ name })) }

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
      runner { @app.start(%W(host add #{ name })) }
      runner { @app.start(%W(host addvar #{ name } #{ var })) }

      actual = runner { @app.start(%W(host get #{ name })) }
        
      mock = {}
      mock[name.to_sym] = {}
      mock[name.to_sym][:groups] = ['ungrouped']
      mock[name.to_sym][:hostvars] = {foo: 'bar'}
        
      desired = {}
      desired[:STDOUT] = mock.to_yaml
       
      expected(actual, desired)
    end
  end
end
