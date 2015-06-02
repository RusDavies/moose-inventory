require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects. Why not?
# For now, we'll check against instance_methods.


RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join(TestHelpers.specdir, 'config/config.yml'),
      format:  "yaml",
      env:     "test"
    }

    @mockargs = []
    @mockarg_parts.each do |key, val|
      @mockargs << "--#{key}"
      @mockargs << val
    end

    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @db = Moose::Inventory::DB
    @db.init
    
    @host = Moose::Inventory::Cli::Host
  end

  before(:each) do
    @db.reset
  end
  
  describe 'add' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:add)
      expect( result ).to eq(true)
    end

    it 'should bail if given no arguments' do
    end
        
    it 'should add a host to the db' do
      name = 'test-host-add'
      args = 'add #{name}'.split(' ')
      @host.start(args)
    end
  end

  describe 'get' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:get)
      expect( result ).to eq(true)
    end
  end
  describe 'list' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:list)
      expect( result ).to eq(true)
    end
  end
  
  describe 'rm' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:rm)
      expect( result ).to eq(true)
    end
  end
  
  describe 'addgroup' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:addgroup)
      expect( result ).to eq(true)
    end
  end
  
  describe 'rmgroup' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:rmgroup)
      expect( result ).to eq(true)
    end
  end  

  describe 'addvar' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:addvar)
      expect( result ).to eq(true)
    end
  end  

  describe 'rmvar' do
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:rmvar)
      expect( result ).to eq(true)
    end
  end  
end
