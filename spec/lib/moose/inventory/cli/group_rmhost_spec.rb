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

    @console = Moose::Inventory::Cli::Formatter
    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @group = Moose::Inventory::Cli::Group
    @host = Moose::Inventory::Cli::Host
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #====================
  describe 'rmgroup' do
    #----------------
    it 'should be responsive' do
      result = @group.instance_methods(false).include?(:rmhost)
      expect(result).to eq(true)
    end
    
    #----------------

    #------------------------
    it '<missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w(group rmhost)) # <- no group or hosts given
      end

      # Check output
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP GROUP ... should abort if the group does not exist' do
      group_name = 'not-a-group'
      host_name = 'example'
      actual = runner do
        @app.start(%W(group rmhost #{group_name} #{host_name}))
      end

      # Check output
      desired = { aborted: true}
      desired[:STDOUT] = 
        "Dissociate group '#{group_name}' from host(s) '#{host_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"
      desired[:STDERR] = 
        "ERROR: The group '#{group_name}' does not exist.\n"\
        "An error occurred during a transaction, any changes have been rolled back.\n"
      expected(actual, desired)
    end
 
    #------------------------
    it 'GROUP HOST ... should dissociate the group from an existing group' do
      host_name = 'test1'
      group_name = 'group1'

      runner { @app.start(%W(host add #{host_name})) }
      runner { @app.start(%W(group add #{group_name})) }
      runner { @app.start(%W(group addhost #{group_name} #{host_name} )) }

      #
      # Dissociate the host
      # 1. expect that the group association is removed
      # 2. expect that no association with ungrouped is made.
      
      actual = runner do
        @app.start(%W(group rmhost #{group_name} #{host_name} )) 
      end
      
      #@console.dump(actual, 'y')
      
      # rubocop:disable Metrics/LineLength
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Dissociate group '#{group_name}' from host(s) '#{host_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"\
        "  - remove association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - OK\n"\
        "  - add automatic association {group:ungrouped <-> host:#{host_name}}...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts.count).to eq(0)
    end
    
    #------------------------
    it 'GROUP HOST ... should warn about non-existing associations' do
      # 1. Should warn that the association doesn't exist.
      # 2. Should complete with success. (desired state == actual state) 
      
      host_name = 'test_host'
      group_name = 'test_group'
      runner { @app.start(%W(host add #{host_name})) }
      runner { @app.start(%W(group add #{group_name})) }
      runner { @app.start(%W(group addhost #{host_name})) }
    
      actual = runner do
        @app.start(%W(group rmhost #{group_name} #{host_name})) 
      end
     
      # rubocop:disable Metrics/LineLength
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Dissociate group '#{group_name}' from host(s) '#{host_name}':\n"\
        "  - retrieve group \'#{group_name}\'...\n"\
        "    - OK\n"\
        "  - remove association {group:#{group_name } <-> host:#{host_name}}...\n"\
        "    - doesn't exist, skipping.\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] = 
        "WARNING: Association {group:#{group_name} <-> host:#{host_name}} "\
          "doesn't exist, skipping.\n" 

      expected(actual, desired)
    end    

    #------------------------
    it '\'ungrouped\' HOST ... should abort with an error' do

      host_name = 'test_host'
      group_name = 'ungrouped'

      runner { @app.start(%W(host add #{name})) } # <- auto creates the association with ungrouped

      actual = runner { @app.start(%W(group rmhost #{group_name} #{host_name} )) }

      desired = { aborted: true}
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)
    end
    
    #------------------------
    it 'GROUP HOST1 HOST2 ... should dissociate the group from'\
      ' multiple hosts at once' do
      # 1. Should dissociate hosts from the group
      # 2. Should add each host to the 'ungrouped' automatic group
      #    if it has no other groups.

      group_name = 'test_group'
      host_names = %W( test_host1 test_host2 test_host3 )

      runner { @app.start(%W(group add #{group_name} )) }
      runner {  @app.start(%W(group addhost #{group_name}) + host_names)  }
      
      actual = runner do
        @app.start(%W(group rmhost #{group_name}) + host_names)
      end

      #@console.out(actual, 'y')

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false}
      desired[:STDOUT] =
        "Dissociate group '#{group_name}' from host(s) '#{host_names.join(',')}':\n"\
        "  - retrieve group \'#{group_name}\'...\n"\
        "    - OK\n"
      host_names.each do |host|
        desired[:STDOUT] = desired[:STDOUT] +
        "  - remove association {group:#{group_name} <-> host:#{host}}...\n"\
        "    - OK\n"\
        "  - add automatic association {group:ungrouped <-> host:#{host}}...\n"\
        "    - OK\n"\
      end
      desired[:STDOUT] = desired[:STDOUT] +
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts.count).to eq(0)
      host_names.each do |host|
        expect(hosts[name: host]).to be_nil
      end
    end         
  end
end
