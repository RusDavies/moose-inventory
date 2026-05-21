require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
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
      result = @host.instance_methods(false).include?(:rmgroup)
      expect(result).to eq(true)
    end

    #----------------

    #------------------------
    it 'host rmgroup <missing args> ... should abort with an error' do
      actual = runner do
        @app.start(%w(host rmgroup)) # <- no group given
      end

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host rmgroup HOST GROUP ... should abort if the host does not exist' do
      host_name = 'not-a-host'
      group_name = 'example'
      actual = runner do
        @app.start(%W(host rmgroup #{host_name} #{group_name}))
      end

      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Dissociate host '#{host_name}' from groups '#{group_name}':\n"\
        "  - Retrieve host '#{host_name}'...\n"
      desired[:STDERR] =
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The host '#{host_name}' was not found in the database.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host rmgroup HOST GROUP ... should dissociate the host from an existing group' do
      # 1. Should rm the host to the group
      # 2. Should add the host from the 'ungrouped' automatic group
      #    if it has no other groups.

      host_name = 'test1'
      runner { @app.start(%W(host add #{host_name})) }

      group_names = %w(group1 group2)
      tmp = runner { @app.start(%W(host addgroup #{host_name} #{group_names[0]} #{group_names[1]})) }

      #
      # Dissociate from the first group
      # 1. expect that the group association is removed
      # 2. expect that no association with ungrouped is made.

      actual = runner do
        @app.start(%W(host rmgroup #{host_name} #{group_names[0]}))
      end
      # @console.dump(actual, 'y')

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false }
      desired[:STDOUT] =
        "Dissociate host '#{host_name}' from groups '#{group_names[0]}':\n"\
        "  - Retrieve host '#{host_name}'...\n"\
        "    - OK\n"\
        "  - Remove association {host:#{host_name} <-> group:#{group_names[0]}}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      host = @db.models[:host].find(name: host_name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: group_names[0]]).to be_nil
      expect(groups[name: group_names[1]]).not_to be_nil
      expect(groups[name: 'ungrouped']).to be_nil # redundant, but for clarity!

      #
      # Remove the second group
      # 1. expect that the group association is removed
      # 2. expect that an association will be made with 'ungrouped'.
      actual = runner do
        @app.start(args = %W(host rmgroup #{host_name} #{group_names[1]}))
      end

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false }
      desired[:STDOUT] =
        "Dissociate host '#{host_name}' from groups '#{group_names[1]}':\n"\
        "  - Retrieve host '#{host_name}'...\n"\
        "    - OK\n"\
        "  - Remove association {host:#{host_name} <-> group:#{group_names[1]}}...\n"\
        "    - OK\n"\
        "  - Add automatic association {host:#{host_name} <-> group:ungrouped}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      host = @db.models[:host].find(name: host_name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: group_names[0]]).to be_nil
      expect(groups[name: group_names[1]]).to be_nil
      expect(groups[name: 'ungrouped']).not_to be_nil
    end

    #------------------------
    it 'host rmgroup HOST GROUP ... should warn about non-existing associations' do
      # 1. Should warn that the group doesn't exist.
      # 2. Should complete with success. (desired state == actual state)

      host_name = 'test1'
      group_name = 'no-group'
      runner { @app.start(%W(host add #{host_name})) }

      actual = runner do
        @app.start(%W(host rmgroup #{host_name} #{group_name}))
      end

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false }
      desired[:STDOUT] =
        "Dissociate host '#{host_name}' from groups '#{group_name}':\n"\
        "  - Retrieve host \'#{host_name}\'...\n"\
        "    - OK\n"\
        "  - Remove association {host:#{host_name} <-> group:#{group_name}}...\n"\
        "    - Doesn't exist, skipping.\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      desired[:STDERR] = "WARNING: Association {host:#{host_name} <-> group:#{group_name}} doesn't exist, skipping.\n"

      expected(actual, desired)
    end

    #------------------------
    it 'host rmgroup HOST \'ungrouped\' ... should abort with an error' do
      name = 'test1'
      groupname = 'ungrouped'

      runner { @app.start(%W(host add #{name})) }

      actual = runner { @app.start(%W(host rmgroup #{name} #{groupname})) }

      desired = { aborted: true }
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host rmgroup GROUP1 GROUP1 ... should dissociate the host from'\
      ' multiple groups at once' do
      # 1. Should rm the host to the group
      # 2. Should add the host from the 'ungrouped' automatic group
      #    if it has no other groups.

      host_name = 'test1'
      runner { @app.start(%W(host add #{host_name})) }

      group_names = %w(group1 group2)
      group_names.each do |group|
        runner { @app.start(%W(host addgroup #{host_name} #{group})) }
      end

      actual = runner do
        @app.start(%W(host rmgroup #{host_name}) + group_names)
      end
      desired = { aborted: false }
      desired[:STDOUT] =
        "Dissociate host '#{host_name}' from groups '#{group_names.join(',')}':\n"\
        "  - Retrieve host \'#{host_name}\'...\n"\
        "    - OK\n"
      group_names.each do |group|
        desired[:STDOUT] = desired[:STDOUT] +
                           "  - Remove association {host:#{host_name} <-> group:#{group}}...\n"\
                           "    - OK\n"\
      end
      desired[:STDOUT] = desired[:STDOUT] +
                         "  - Add automatic association {host:#{host_name} <-> group:ungrouped}...\n"\
                         "    - OK\n"\
                         "  - All OK\n"\
                         "Succeeded\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      host = @db.models[:host].find(name: host_name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      group_names.each do |group|
        expect(groups[name: group]).to be_nil
      end
      expect(groups[name: 'ungrouped']).not_to be_nil # redundant, but for clarity!
    end
  end
end
