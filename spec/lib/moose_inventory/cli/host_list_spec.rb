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

    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @console = Moose::Inventory::Cli::Formatter
    @host = Moose::Inventory::Cli::Host
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #====================
  describe 'list' do
    #---------------------
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:list)
      expect(result).to eq(true)
    end

    #---------------------
    it 'should return an empty set when no results' do
      # no items in the db
      name = 'not-in-db'
      actual = runner { @app.start(%W(host list)) }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'should get a list of hosts from the db' do
      var = 'foo=bar'
      
      mock = {}
      hosts = %w(host1 host2 host3)
      hosts.each do |name|
        runner { @app.start(%W(host add #{name})) }
        runner { @app.start(%W(host addvar #{ name } foo=bar)) }
        mock[name.to_sym] = {}
        mock[name.to_sym][:groups] = ['ungrouped']
        mock[name.to_sym][:hostvars] = {foo: 'bar'}
      end

      # items should now be in the db
      actual = runner{ @app.start(%w(host list)) }
        
      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end
    #---------------------
    it 'should be an alias of --hosts (i.e. Ansible parameter)' do
      
      mock = {}
      hosts = %w(host1 host2)
      hosts.each do |name|
        runner { @app.start(%W(host add #{name})) }
        mock[name.to_sym] = {}
        mock[name.to_sym][:groups] = ['ungrouped']
      end

      args = @mockargs.clone
      args << "--hosts"
      cli = Moose::Inventory::Cli 

      # items should now be in the db
      actual = runner{ cli.start(args) }
        
      #@console.out(actual, 'y')
      
      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end
    
  end
end
