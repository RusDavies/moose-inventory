require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Group do
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join(spec_root, 'config/config.yml'),
      format:  'yaml',
      env:     'test',
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
    @host  = Moose::Inventory::Cli::Host
    @app   = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #=======================
  describe 'addhost' do
    #------------------------
    it 'Group.addhost() should be responsive' do
      result = @group.instance_methods(false).include?(:addhost)
      expect(result).to eq(true)
    end

    #------------------------
    it 'addhost <missing args> ... should abort with an error' do
      actual = runner do
        @app.start(%w(group addhost)) # <- no group given
      end

      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP HOST ... should abort if the group does not exist' do
      host_name = 'example'
      group_name = 'not-a-group'

      actual = runner do
        @app.start(%W(group addhost #{group_name} #{host_name}))
      end

      # @console.out(actual, 'y')
      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Associate group '#{group_name}' with host(s) '#{host_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"
      desired[:STDERR] =
        "ERROR: The group '#{group_name}' does not exist.\n"\
        "An error occurred during a transaction, any changes have been rolled back.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP HOST... should add the host to an existing group' do
      # 1. Should add the host to the group
      # 2. Should remove the host from the 'ungrouped' automatic group

      host_name = 'test1'
      group_name = 'testgroup1'

      runner { @app.start(%W(host add #{host_name})) }
      @db.models[:group].create(name: group_name)

      actual = runner { @app.start(%W(group addhost #{group_name} #{host_name})) }

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false }
      desired[:STDOUT] =
        "Associate group '#{group_name}' with host(s) '#{host_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - OK\n"\
        "  - remove automatic association {group:ungrouped <-> host:#{host_name}}...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded.\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      host = @db.models[:host].find(name: host_name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: group_name]).not_to be_nil
      expect(groups[name: 'ungrouped']).to be_nil # redundant, but for clarity!
    end

    #------------------------
    it '\'ungrouped\' HOST... should abort with an error' do
      host_name = 'test1'
      group_name = 'ungrouped'

      runner { @app.start(%W(host add #{host_name})) }

      actual = runner { @app.start(%W(group addhost #{group_name} #{host_name})) }

      desired = { aborted: true }
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP HOST ... should add the host to an group, creating the host if necessary' do
      host_name = 'test1'
      group_name = 'testgroup1'

      runner { @app.start(%W(group add #{group_name})) }

      # DON'T CREATE THE HOST! That's the point of the test. ;o)

      actual = runner { @app.start(%W(group addhost #{group_name} #{host_name})) }

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Associate group '#{group_name}' with host(s) '#{host_name}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - host does not exist, creating now...\n"\
        "      - OK\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Host '#{host_name}' does not exist and will be created.\n"
      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts.count).to eq(1)
      expect(hosts[name: host_name]).not_to be_nil
    end

    #------------------------
    it 'GROUP HOST... should skip associations that already '\
       ' exist, but raise a warning.' do
      host_name = 'test1'
      group_name = 'testgroup1'

      runner { @app.start(%W(group add #{group_name})) }
      runner { @app.start(%W(host add #{host_name})) }

      # Run once to make the initial association
      runner { @app.start(%W(group addhost #{group_name} #{host_name})) }

      # Run again, to prove expected result
      actual = runner { @app.start(%W(group addhost #{group_name} #{host_name})) }

      # @console.out(actual,'y')

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Associate group '#{group_name}' with host(s) '#{host_name}':\n"\
        "  - retrieve group \'#{group_name}\'...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - already exists, skipping.\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Association {group:#{group_name} <-> host:#{host_name}} already exists, skipping.\n"
      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts.count).to eq(1)
      expect(hosts[name: host_name]).not_to be_nil
    end

    #------------------------
    it 'GROUP HOST1 HOST2 ... should associate the group with '\
      ' multiple hosts at once' do
      group_name = 'test1'
      host_names = %w(host1 host2 host3)

      runner { @app.start(%W(group add #{group_name})) }
      host_names.each do |host|
        runner { @app.start(%W(host add #{host})) }
      end

      actual = runner { @app.start(%W(group addhost #{group_name}) + host_names) }

      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: false, STDERR: '' }
      desired[:STDOUT] =
        "Associate group '#{group_name}' with host(s) '#{host_names.join(',')}':\n"\
        "  - retrieve group '#{group_name}'...\n"\
        "    - OK\n"
      host_names.each do |host|
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - add association {group:#{group_name} <-> host:#{host}}...\n"\
                           "    - OK\n"\
                           "  - remove automatic association {group:ungrouped <-> host:#{host}}...\n"\
                           "    - OK\n"\

        # desired[:STDERR] = desired[:STDERR] +
        #  "WARNING: Host '#{host}' does not exist and will be created.\n"
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - all OK\n"\
                         "Succeeded.\n"
      expected(actual, desired)

      # We should have group associations
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts).not_to be_nil
      expect(hosts.count).to eq(3)
    end
  end
end
