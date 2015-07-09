require 'spec_helper'

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

    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @console = Moose::Inventory::Cli::Formatter
    @group = Moose::Inventory::Cli::Group
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
      result = @group.instance_methods(false).include?(:listvars)
      expect(result).to eq(true)
    end
     
    #-----------------
    it '<missing args> ... should abort with an error' do
      actual = runner  {  @app.start(%w(group listvars))  }

      # Check output
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end
    
    #-----------------
    it '--ansible <missing args> ... should abort with an error' do
      
      args = @mockargs.clone
      args.concat( %w(--ansible group listvars) ).flatten
    
      actual = runner{ @cli.start(args) }
 
      # Check output
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments for Ansible mode, 0 for 1.\n"
      expected(actual, desired)
    end
    
    #------------------------
    it 'GROUP ... should return a list of group variables grouped by group' do
      group_name ='test_group'
      group_vars = %w(foo=bar cow=chicken)
      
      tmp = runner {  @app.start(%W(group add #{group_name} )) }
      tmp = runner {  @app.start(%W(group addvar #{group_name} #{group_vars[0]} #{group_vars[1]})) }
      
      actual = runner do
        @app.start(%W(group listvars #{group_name}))
      end

      #@console.out(actual, 'y')
      
      # Check output
      mock = {}
      mock[group_name.to_sym] = {} 
      group_vars.each do |hv|
        hv_array = hv.split('=')  
        mock[group_name.to_sym][hv_array[0].to_sym] = hv_array[1] 
      end
      
      desired = {}
      desired[:STDOUT] = mock.to_yaml
      expected(actual, desired)
    end
    
    #------------------------
    it '--ansible GROUP ... should return a list of group variables, in a  style akin to Ansible\'s \'--host HOSTNAME\'' do
      group_name ='test_group'
      group_vars = %w(foo=bar cow=chicken)
      
      tmp = runner {  @app.start(%W(group add #{group_name} )) }
      tmp = runner {  @app.start(%W(group addvar #{group_name} #{group_vars[0]} #{group_vars[1]})) }
      
      actual = runner do
        @cli.start(%W(--ansible group listvars #{group_name}))
      end
    
      #@console.out(actual, 'y')
      
      # Check output
      mock = {}
      group_vars.each do |hv|
        hv_array = hv.split('=')  
        mock[hv_array[0].to_sym] = hv_array[1] 
      end
      
      desired = {}
      desired[:STDOUT] = mock.to_json + "\n"
      expected(actual, desired)
    end
  end
end
