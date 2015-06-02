require 'spec_helper'

RSpec.describe "Moose::Inventory::DB" do
  #=============================
  # Initialization
  #
  
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join( spec_dir, 'config/config.yml'),
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
    
    @db      = Moose::Inventory::DB
  end
  
  #=============================
  # Tests
  #
  
  describe ".init()" do
    it 'should be responsive' do
      result = @db.respond_to?(:init)
      expect(result).to eq(true)
    end

    it 'shouldn\'t throw an error' do
      failed = false
      begin
        @db.init
      rescue Exception => e
        p e
        failed = true
      end
      
      expect(failed).to eq(false)
    end
  end

  describe "._db" do
    it 'should be responsive' do
      result = @db.respond_to?(:_db)
    end
    
    it 'should not be nil' do
      expect(@db._db).not_to be_nil
    end
  end      
  
  describe 'tables' do
    it 'should have a hosts table' do
       hosts_schema = @db._db.schema(:hosts)
    end

    it 'should have a hostsvars table' do
       hosts_schema = @db._db.schema(:hostvars)
    end    
    it 'should have a groups table' do
       hosts_schema = @db._db.schema(:groups)
    end

    it 'should have a groupvars table' do
       hosts_schema = @db._db.schema(:groupvars)
    end

    it 'should have a groups_hosts table' do
       hosts_schema = @db._db.schema(:groups_hosts)
    end
  end

  describe ".reset()" do
    it 'should be responsive' do
      result = @db.respond_to?(:reset)
    end
    
    it 'should purge the database of contents' do
      # Put at least one host and one group into the database
      Moose::Inventory::DB::Host.create(name: "reset-host")
      Moose::Inventory::DB::Group.create(name: "reset-group")

      # Reset the DB
      @db.reset

      #
      hosts = Moose::Inventory::DB::Host.all
      expect(hosts.count).to eq(0)

      group = Moose::Inventory::DB::Group.all
      expect(group.count).to eq(0)
    end
  end
  
  describe ".transaction()" do
    before(:each) do
      @db.reset  
    end
    
    it "should be responsive" do
      result = @db.respond_to?(:transaction)
      expect(result).to eq(true)
    end

    it "should perform transactions" do
      
      hosts = nil
      
      hosts = Moose::Inventory::DB::Host.all
      initial_count = hosts.count
      
      @db.transaction do 
        host = Moose::Inventory::DB::Host.create(name: "transaction1")
        host = Moose::Inventory::DB::Host.create(name: "transaction2")
      end

      # Do a follow-up transaction, to see if we can trigger the
      # 'write only db' error. 
      @db.transaction do
        host = Moose::Inventory::DB::Host.create(name: "transaction3")
        host = Moose::Inventory::DB::Host.create(name: "transaction4")
      end
      
      # Check what's in the db now (should be 4 new hosts).
      hosts = Moose::Inventory::DB::Host.all
      expect(hosts.count).to eq(initial_count + 4) 
    end

    it "should rollback failed transactions" do
      hosts = Moose::Inventory::DB::Host.all
      initial_count = hosts.count

      @db._db.transaction(:savepoint=>true) do
        host = Moose::Inventory::DB::Host.create(name: "rollback1")
        raise Sequel::Rollback #
        host = Moose::Inventory::DB::Host.create(name: "rollback2")
      end
      
      hosts = Moose::Inventory::DB::Host.all
      expect(hosts.count).to eq( initial_count )
    end
  
  end
end
