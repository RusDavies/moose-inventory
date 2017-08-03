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
    @mockargs << '--trace' # extra info for debugging

    @console = Moose::Inventory::Cli::Formatter

    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @host = Moose::Inventory::Cli::Host
    @group = Moose::Inventory::Cli::Group
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  # ============================
  describe 'add' do
    # --------------------
    it 'Group.add() method should be responsive' do
      result = @group.instance_methods(false).include?(:add)
      expect(result).to eq(true)
    end

    # --------------------
    it '<no arguments> ... should bail with an error' do
      actual = runner { @app.start(%w(group add)) }

      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end

    # --------------------
    it 'ungrouped ... should abort with an error' do
      actual = runner { @app.start(%w(group add ungrouped)) }

      # Check output
      desired = { aborted: true }
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'\n"
      expected(actual, desired)
    end

    # --------------------
    it 'GROUP ... should add a group to the db' do
      name = 'test'
      actual = runner { @app.start(%W(group add #{name})) }

      # @console.out(actual)

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add group '#{name}':\n"\
        "  - create group...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded\n"

      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: name)
      expect(group[:name]).to eq(name)
    end

    # --------------------
    it 'GROUP ... should skip GROUP creation if it already exists' do
      name = 'test-group'
      @db.models[:group].create(name: name)

      actual = runner { @app.start(%W(group add #{name})) }

      # @console.out(actual)

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add group '#{name}':\n"\
        "  - create group...\n"\
        "    - already exists, skipping.\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Group '#{name}' already exists, skipping creation.\n"

      expected(actual, desired)

      expected(actual, desired)
    end

    # --------------------
    it 'GROUP1 GROUP2 GROUP3 ... should add multiple groups' do
      names = %w(test1 test2 test3)

      actual = runner { @app.start(%w(group add) + names) }

      # @console.out(actual)

      # Check output
      desired = { STDOUT: '' }
      names.each do |name|
        desired[:STDOUT] = desired[:STDOUT] +
                           "Add group '#{name}':\n"\
                           "  - create group...\n"\
                           "    - OK\n"\
                           "  - all OK\n"\
      end
      desired[:STDOUT] = desired[:STDOUT] + "Succeeded\n"

      expected(actual, desired)

      # Check db
      names.each do |name|
        group = @db.models[:group].find(name: name)
        expect(group[:name]).to eq(name)
      end
    end

    # --------------------
    it 'GROUP1 --hosts HOST1 ... should add the '\
      'group and associate it with existing hosts' do

      host_name = 'test-host'
      @db.models[:host].create(name: host_name)

      group_name = 'test-group'
      actual = runner do
        @app.start(%W(group add #{group_name} --hosts #{host_name}))
      end

      # @console.out(actual)

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add group '#{group_name}':\n"\
        "  - create group...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded\n"

      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts).not_to be_nil
      expect(hosts.count).to eq(1)
      expect(hosts[name: host_name]).not_to be_nil
    end

    # --------------------
    it 'GROUP1 --hosts HOST ... should create HOST if necessary, and warn' do
      host_name = 'test-host'

      # DON'T CREATE THE HOST! That's the point!

      group_name = 'test-group'
      actual = runner do
        @app.start(%W(group add #{group_name} --hosts #{host_name}))
      end

      # @console.out(actual)

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add group '#{group_name}':\n"\
        "  - create group...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - host doesn't exist, creating now...\n"\
        "      - OK\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Host '#{host_name}' doesn't exist, but will be created.\n"

      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts).not_to be_nil
      expect(hosts.count).to eq(1)
      expect(hosts[name: host_name]).not_to be_nil
    end

    # --------------------
    it 'GROUP1 --hosts HOST ... should skip if association already exists, and warn' do
      host_name = 'test-host'
      group_name = 'test-group'

      # Create group and association
      runner { @app.start(%W(group add #{group_name} --hosts #{host_name})) }

      # Do it again, to prove that we skip
      actual = runner do
        @app.start(%W(group add #{group_name} --hosts #{host_name}))
      end

      # @console.out(actual, 'y')

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add group '#{group_name}':\n"\
        "  - create group...\n"\
        "    - already exists, skipping.\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
        "    - already exists, skipping.\n"\
        "    - OK\n"\
        "  - all OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Group '#{group_name}' already exists, skipping creation.\n"\
        "WARNING: Association {group:#{group_name} <-> host:#{host_name}} already exists, skipping creation.\n"

      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts).not_to be_nil
      expect(hosts.count).to eq(1)
      expect(hosts[name: host_name]).not_to be_nil
    end

    # --------------------
    it 'GROUP --hosts HOST1,HOST2 ... should add the group and '\
      'associate it with multiple hosts' do

      # The group should be added
      # Each host should be associated with the group
      # Each host should be removed from the automatic 'ungrouped' group

      group_name = 'test-group'
      host_names = %w(host1 host2 host3)

      # Add just the first host. This ensure that we cover paths for both
      # and existing host (with an 'ungrouped' association) and for none
      # existing groups.
      tmp = runner { @app.start(%W(host add #{host_names[0]})) }

      # @console.out(tmp,  'y')

      # Now run the actual group addition
      actual = runner do
        @app.start(%W(group add #{group_name} --hosts #{host_names.join(',')}))
      end

      # @console.out(actual,'y')

      # Check output
      desired = { aborted: false, STDERR: '', STDOUT: '' }
      desired[:STDOUT] =
        "Add group '#{group_name}':\n"\
        "  - create group...\n"\
        "    - OK\n"\
        "  - add association {group:#{group_name} <-> host:#{host_names[0]}}...\n"\
        "    - OK\n"\
        "  - remove automatic association {group:ungrouped <-> host:#{host_names[0]}}...\n"\
        "    - OK\n"

      host_names.slice(1, host_names.length - 1).each do |host_name|
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - add association {group:#{group_name} <-> host:#{host_name}}...\n"\
                           "    - host doesn't exist, creating now...\n"\
                           "      - OK\n"\
                           "    - OK\n"
        desired[:STDERR] = desired[:STDERR] +
                           "WARNING: Host '#{host_name}' doesn't exist, but will be created.\n"
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - all OK\n"\
                         "Succeeded, with warnings.\n"

      expected(actual, desired)

      # Check db
      group = @db.models[:group].find(name: group_name)
      hosts = group.hosts_dataset
      expect(hosts.count).to eq(host_names.count)
      hosts.each do |host|
        groups_ds = host.groups_dataset
        expect(groups_ds.count).to eq(1)
        expect(groups_ds[name: 'ungrouped']).to be_nil # i.e. not 'ungrouped'
      end
    end

    # --------------------
    it 'HOST --groups GROUP1,ungrouped ... should bail '\
      'with an error' do
      name = 'testhost'
      group_names = %w(group1 ungrouped)

      actual = runner do
        @app.start(%W(host add #{name} --groups #{group_names.join(',')}))
      end

      # Check output
      desired = { aborted: true, STDERR: '', STDOUT: '' }
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"

      expected(actual, desired)
    end

    # --------------------
    it 'HOST1 HOST2 --groups GROUP1,GROUP2 ... should add multiple '\
      'groups, associating each with multiple hosts' do
      #
      host_names = %w(host1 host2 host3)
      # Note, relies on auto-generation of hosts

      group_names = %w(group1 group2 group3)
      actual = runner do
        @app.start(%w(group add) + group_names + %W(--hosts #{host_names.join(',')}))
      end

      # @console.out(actual,'y')

      # Check output
      desired = { aborted: false, STDERR: '', STDOUT: '' }
      first_pass = true
      group_names.each do |group|
        desired[:STDOUT] = desired[:STDOUT] +
                           "Add group '#{group}':\n"\
                           "  - create group...\n"\
                           "    - OK\n"

        host_names.each do |host|
          desired[:STDOUT] = desired[:STDOUT] +
                             "  - add association {group:#{group} <-> host:#{host}}...\n"
          if first_pass
            desired[:STDOUT] = desired[:STDOUT] +
                               "    - host doesn't exist, creating now...\n"\
                               "      - OK\n"
          end
          desired[:STDOUT] = desired[:STDOUT] +
                             "    - OK\n"
        end
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - all OK\n"
        first_pass = false
      end

      desired[:STDOUT] = desired[:STDOUT] + "Succeeded, with warnings.\n"
      host_names.each do |host|
        desired[:STDERR] = desired[:STDERR] +
                           "WARNING: Host '#{host}' doesn't exist, but will be created.\n"
      end
      expected(actual, desired)

      # Check db
      group_names.each do |name|
        group = @db.models[:group].find(name: name)
        expect(group).not_to be_nil
        hosts = group.hosts_dataset
        expect(hosts.count).to eq(host_names.count)
        host_names.each do |host|
          expect(hosts[name: host]).not_to be_nil
          expect(hosts[name: host].groups_dataset[name: 'ungrouped']).to be_nil
        end
      end
    end
  end
end
