require 'spec_helper'

RSpec.describe "Moose::Inventory::DB - models" do
  #=============================
  # Initialization
  #

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
  end

  before(:each) do
    @db.reset
  end

  #=============================
  # Tests
  #
  describe 'Hostvars model' do
    it 'should be be functional per Sequel' do
      name = 'hostvar-test'
      val = "1"

      Moose::Inventory::DB::Hostvar.create( name: name , value: val )

      hostvar = Moose::Inventory::DB::Hostvar.find( name: name )

      expect(hostvar).not_to be_nil
      expect(hostvar[:name]).to eq( name )
      expect(hostvar[:value]).to eq( val )
    end
  end

  describe 'Host model' do
    it 'should be be functional per Sequel' do
      Moose::Inventory::DB::Host.create(name: 'Host-test')
      host = Moose::Inventory::DB::Host.find(name: 'Host-test')
      expect(host).not_to be_nil
      expect(host[:name]).to eq('Host-test')
    end

    it 'should have relationships with Groups' do
      host = Moose::Inventory::DB::Host.create(name: 'Host-test')
      group = Moose::Inventory::DB::Group.create(name: 'Group-test')

      host.add_group(group)

      host = Moose::Inventory::DB::Host.find(name: 'Host-test')
      groups = host.groups_dataset

      expect(groups).not_to be_nil
      expect(groups.count).to eq(1)
      expect(groups.first[:name]).to eq('Group-test')
    end

    it 'should have relationships with Hostvars' do
      hostname = 'host-test'
      hostvarname = 'hostvar-test'
      hostvarval = '1'

      host = Moose::Inventory::DB::Host.create(name: hostname)
      hostvar = Moose::Inventory::DB::Hostvar.create(name: hostvarname, value: hostvarval)

      host.add_hostvar(hostvar)

      host = Moose::Inventory::DB::Host.find(name: hostname)
      hostvars = host.hostvars_dataset

      expect(hostvars).not_to be_nil
      expect(hostvars.count).to eq(1)
      expect(hostvars.first[:name]).to eq(hostvarname)
      expect(hostvars.first[:value]).to eq(hostvarval)
    end

  end

  describe 'Groupvars model' do
    it 'should be be functional per Sequel' do
      name = 'groupvar-test'
      val = '1'

      Moose::Inventory::DB::Groupvar.create(name: name, value: val)

      groupvar = Moose::Inventory::DB::Groupvar.find(name: name)

      expect(groupvar).not_to be_nil
      expect(groupvar[:name]).to eq( name )
      expect(groupvar[:value]).to eq( val )
    end
  end

  describe 'Group model' do
    it 'should be be functional per Sequel' do
      Moose::Inventory::DB::Group.create(name: 'Group-test')
      group = Moose::Inventory::DB::Group.find(name: 'Group-test')
      expect(group).not_to be_nil
      expect(group[:name]).to eq('Group-test')
    end

    it 'should have relationships with Hosts' do
      group = Moose::Inventory::DB::Group.create(name: 'Group-test')
      host = Moose::Inventory::DB::Host.create(name: 'Host-test')

      group.add_host(host)

      group = Moose::Inventory::DB::Group.find(name: 'Group-test')
      hosts = group.hosts_dataset

      expect(hosts).not_to be_nil
      expect(hosts.count).to eq(1)
      expect(hosts.first[:name]).to eq('Host-test')
    end
  end

  it 'should have relationships with Hostvars' do
    groupname = 'group-test'
    groupvarname = 'groupvar-test'
    groupvarval = '1'

    group = Moose::Inventory::DB::Group.create(name: groupname)
    groupvar = Moose::Inventory::DB::Groupvar.create(name: groupvarname, value: groupvarval)

    group.add_groupvar(groupvar)

    group = Moose::Inventory::DB::Group.find(name: groupname)
    groupvars = group.groupvars_dataset

    expect(groupvars).not_to be_nil
    expect(groupvars.count).to eq(1)
    expect(groupvars.first[:name]).to eq(groupvarname)
    expect(groupvars.first[:value]).to eq(groupvarval)
  end

end
