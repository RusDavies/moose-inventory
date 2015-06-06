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

  #==================
  describe 'addvar' do
    #-----------------
    it 'should be responsive' do
      result = @host.instance_methods(false).include?(:addvar)
      expect(result).to eq(true)
    end
    
    #-----------------
    it 'host addvar <missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w(host addvar)) # <- no group given
      end

      # Check output
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host addvar HOST key=value ... should abort if the host does not exist' do
      actual = runner do
        @app.start(%w(host addvar not-a-host bob=me))
      end

      # Check output
      desired = { aborted: true}
      desired[:STDOUT] = 'Retrieving host \'not-a-host\'... '
      desired[:STDERR] = 
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The host 'not-a-host' was not found in the database.\n"
      expected(actual, desired)
    end

    #------------------------
     it 'host addvar HOST <malformed> ... should abort with an error' do
       # 1. Should add the var to the db
       # 2. Should associate the host with the var
       
       name = 'test1'
       @db.models[:host].create(name: name)
 
       var  = {name: 'var1', value: "testval"}
       cases = %W(
         testvar 
         testvar= 
         =testval 
         testvar=testval=
         =testvar=testval
         testvar=testval=extra
       )      
     
       cases.each do |args| 
         actual = runner do
           @app.start(%W(host addvar #{name} #{args} ))
         end
         #@console.out(actual,'p')
   
         desired = { aborted: true}
         desired[:STDOUT] = 
           "Retrieving host \'#{name}\'... OK\n"\
           "Adding hostvar {#{args}}... "
         desired[:STDERR] = 
           "An error occurred during a transaction, any changes have been rolled back.\n"\
           "ERROR: Incorrect format in {#{args}}. Expected 'key=value'.\n"
           
         expected(actual, desired)
       end
     end
    
    #------------------------
    it 'host addvar HOST key=-value ... should associate the host with the key/value pair' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var
      
      name = 'test1'
      var  = {name: 'var1', value: "testval"}

      @db.models[:host].create(name: name)
      
      actual = runner do
        @app.start(%W(host addvar #{name} #{var[:name]}=#{var[:value]} ))
      end
      #@console.out(actual,'p')
      
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Retrieving host \'#{name}\'... OK\n"\
        "Adding hostvar {#{var[:name]}=#{var[:value]}}... OK\n"\
        "Succeeded\n"
      expected(actual, desired)

      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(1)
      expect(hostvars[name: var[:name]]).not_to be_nil
      expect(hostvars[name: var[:name]][:value]).to eq(var[:value])
    end
   

    #------------------------
    it 'host addvar HOST key=value ... should update an already existing association' do
      # 1. Should add the var to the db
      # 2. Should associate the host with the var
      
      name = 'test1'
      var  = {name: 'var1', value: "testval"}
    
      @db.models[:host].create(name: name)
      runner { @app.start(%W(host addvar #{name} #{var[:name]}=#{var[:value]} )) }
    
      var[:value]  = "newtestval"
      actual = runner do
        @app.start(%W(host addvar #{name} #{var[:name]}=#{var[:value]} ))
      end
      #@console.out(actual,'p')
      
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Retrieving host \'#{name}\'... OK\n"\
        "Adding hostvar {#{var[:name]}=#{var[:value]}}... OK\n"\
        "Succeeded\n"
      expected(actual, desired)
    
      # We should have the correct hostvar associations
      host = @db.models[:host].find(name: name)
      hostvars = host.hostvars_dataset
      expect(hostvars.count).to eq(1)
      expect(hostvars[name: var[:name]]).not_to be_nil
      expect(hostvars[name: var[:name]][:value]).to eq(var[:value])
        
      hostvars = @db.models[:hostvar].all
      expect(hostvars.count).to eq(1)   
    end
  end
end
