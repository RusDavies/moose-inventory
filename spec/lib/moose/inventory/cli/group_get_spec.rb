require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Group do
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

    @group = Moose::Inventory::Cli::Group
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #=======================
  describe 'get' do
    #---------------------
    it 'should be responsive' do
      result = @group.instance_methods(false).include?(:get)
      expect(result).to eq(true)
    end

    #---------------------
    it '<missing args> ... should abort with an error' do
      actual = runner { @app.start(%W(group get)) }

      #@console.out(actual,'y')
      
      desired = {aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more\n"

      expected(actual, desired)
    end
    
    #---------------------
    it "GROUP ... should return an empty set when GROUP doesn't exist" do
      group_name = 'does-not-exist'
      actual = runner { @app.start(%W(group get #{ group_name })) }

      #@console.out(actual, 'y')
      
      desired = {}
      desired[:STDOUT] = {}.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'GROUP ... should get a group from the db' do
      name = 'test_group'
      runner { @app.start(%W(group add #{ name })) }

      actual = runner { @app.start(%W(group get #{ name })) }

      mock = {}
      mock[name.to_sym] = {}
      # mock[name.to_sym][:hosts] = [] # TODO: Should this be present or not? 
        
      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = mock.to_yaml

      expected(actual, desired)
    end

    #---------------------
    it 'GROUP ... should display groupvars, if any are set' do
      name = 'test_group'
      var = 'foo=bar'
      tmp = runner { @app.start(%W(group add #{ name })) }
      tmp = runner { @app.start(%W(group addvar #{ name } #{ var })) }

      actual = runner { @app.start(%W(group get #{ name })) }
      #@console.out(actual, 'y')
      
      mock = {}
      mock[name.to_sym] = {}
      mock[name.to_sym][:groupvars] = {foo: 'bar'}
        
      desired = {}
      desired[:STDOUT] = mock.to_yaml
       
      expected(actual, desired)
    end
        
  end
end
