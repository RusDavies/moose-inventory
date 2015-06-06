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
    @host  = Moose::Inventory::Cli::Host
    @app   = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #======================
  describe 'rm' do
    #---------------
    it 'Group.rm() should be responsive' do
      result = @group.instance_methods(false).include?(:rm)
      expect(result).to eq(true)
    end

    #---------------
    it '<missing argument> ... should abort with an error' do
      actual = runner { @app.start(%w(host rm)) }

      # Check output
      desired = { aborted: true, STDERR: '', STDOUT: '' }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end
    
    # --------------------
    it 'ungrouped ... should abort with an error' do
      actual = runner { @app.start(%W(group rm ungrouped)) }

      # Check output
      desired = {aborted: true}
      desired[:STDERR] =
        "Cannot manually manipulate the automatic group 'ungrouped'\n"
      expected(actual, desired)
    end    
    

    #---------------
    it 'HOST ... should warn about non-existent groups' do
      # Rationale:
      # The request implies the desired state is that the group is not present
      # If the group is not present, for whatever reason, then the desired state
      # already exists.

      # no items in the db
      group_name = "fake"
      actual = runner {  @app.start(%W(group rm #{group_name})) }
 
      #@console.out(actual,'y')
      desired = {}
      desired[:STDOUT] =
        "Removing the group '#{group_name}'... OK\n"\
        "Succeeded\n"
      desired[:STDERR] =
        "WARNING: The group '#{group_name}' does not exist, skipping.\n"

      expected(actual, desired)
    end

    #---------------
    it 'HOST ... should remove a group' do
      name = 'test1'
      @db.models[:group].create(name: name)

      actual = runner { @app.start(%W(group rm #{name})) }

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Removing the group '#{name}'... OK\n"\
        "Succeeded\n"
      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: name)
      expect(group).to be_nil
    end
    
    #---------------
     fit "HOST ... should handle the automatic 'ungrouped' group for associated hosts" do
       host_name  = 'test-host1'
       group_name  = 'test-group1'

       tmp = runner { @app.start(%W(group add #{group_name} --hosts #{host_name})) }
       expect(tmp[:unexpected]).to eq(false)
       expect(tmp[:aborted]).to eq(false)  
       host = @db.models[:host].find(name: host_name)
       groups_ds = host.groups_dataset
       expect(groups_ds).not_to be_nil
       expect(groups_ds[name: 'ungrouped']).to be_nil # Shouldn't be ungrouped 

       # Now do the rm       
       actual = runner { @app.start(%W(group rm #{group_name})) }
 
       #@console.out(actual)
       
       # Check output
       desired = {}
       desired[:STDOUT] =
         "Remove the group '#{group_name}':\n"\
         "  - Adding automatic association {group:ungrouped <-> host:#{host_name}}... OK\n"\
         "  - OK\n"\
         "Succeeded\n"
       expected(actual, desired)
 
       # Check db
       group = @db.models[:group].find(name: group_name)
       expect(group).to be_nil
       
       host = @db.models[:host].find(name: host_name)
       expect(host).not_to be_nil
       groups_ds = host.groups_dataset
       expect(groups_ds).not_to be_nil
       expect(groups_ds[name: 'ungrouped']).not_to be_nil
     end    

#    #---------------
#    it 'host rm HOST1 HOST2 ... should remove multiple hosts' do
#      names = %w(host1 host2 host3)
#      names.each do |name|
#        @db.models[:host].create(name: name)
#      end
#
#      actual = runner { @app.start(%w(host rm) + names) }
#
#      # Check output
#      desired = { aborted: false, STDERR: '', STDOUT: '' }
#      names.each do |name|
#        desired[:STDOUT] = desired[:STDOUT] +
#                           "Removing the host '#{name}'... OK\n"
#      end
#      desired[:STDOUT] = desired[:STDOUT] + "Success\n"
#      expected(actual, desired)
#
#      # Check db
#      hosts = @db.models[:host].all
#      expect(hosts.count).to eq(0)
#    end
  end
end
