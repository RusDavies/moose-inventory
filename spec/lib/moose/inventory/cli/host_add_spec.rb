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

  # ============================
  describe 'add' do
    # --------------------
    it 'Host.add() method should be responsive' do
      result = @host.instance_methods(false).include?(:add)
      expect(result).to eq(true)
    end

    # --------------------
    it '<no arguments> ... should bail with an error' do
      actual = runner { @app.start(%w(host add)) }
 
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 1 or more.\n"
      expected(actual, desired)
    end

    # --------------------
    it 'HOST ... should add a host to the db' do
      name = 'test-host-add'

      actual = runner { @app.start(%W(host add #{name})) }
      #@console.out(actual,'y')
      
      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add host '#{name}':\n"\
        "  - Creating host '#{name}'...\n"\
        "    - OK\n"\
        "  - Adding automatic association {host:#{name} <-> group:ungrouped}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"

      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      expect(host[:name]).to eq(name)

      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: 'ungrouped']).not_to be_nil
    end

    # --------------------
    it 'HOST ... should skip HOST creation if HOST already exists' do
      name = 'test-host-add'
      runner { @app.start(%W(host add #{name})) }

      actual = runner { @app.start(%W(host add #{name})) }

      # Check output
      desired = {}
      desired[:STDOUT] = 
        "Add host '#{name}':\n"\
        "  - Creating host '#{name}'...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
          
      desired[:STDERR] =
        "WARNING: The host '#{name}' already exists, skipping creation.\n"

      expected(actual, desired)
    end

    # --------------------
    it 'HOST1 HOST2 HOST3 ... should add multiple hosts' do
      names = %w(test1 test2 test3)

      actual = runner { @app.start(%w(host add) + names) }

      # Check output
      desired = {STDOUT: ''}
      names.each do |name|
        desired[:STDOUT] =  desired[:STDOUT] +
          "Add host '#{name}':\n"\
          "  - Creating host '#{name}'...\n"\
          "    - OK\n"\
          "  - Adding automatic association {host:#{name} <-> group:ungrouped}...\n"\
          "    - OK\n"\
          "  - All OK\n"
      end
      desired[:STDOUT] = desired[:STDOUT] + "Succeeded\n"

      expected(actual, desired)

      # Check db
      names.each do |name|
        host = @db.models[:host].find(name: name)
        expect(host[:name]).to eq(name)

        groups = host.groups_dataset
        expect(groups.count).to eq(1)
        expect(groups[name: 'ungrouped']).not_to be_nil
      end
    end

    # --------------------
    it 'HOST1 --groups GROUP ... should add the '\
      'host and associate it with an existing group' do
      group_name = 'testgroup'
      @db.models[:group].create(name: group_name)

      name = 'testhost'
      actual = runner do
        @app.start(%W(host add #{name} --groups #{group_name}))
      end

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add host '#{name}':\n"\
        "  - Creating host '#{name}'...\n"\
        "    - OK\n"\
        "  - Adding association {host:#{name} <-> group:#{group_name}}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"

      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups).not_to be_nil
      expect(groups.count).to eq(1)
      expect(groups[name: group_name]).not_to be_nil # i.e. not 'ungrouped'
    end

    # --------------------
    it 'HOST1 --groups GROUP ... should add the host and associate '\
      ' it with a non-existent group, creating the group' do
      group_name = 'testgroup'

      # DON'T MANUALLY CREATE THE GROUP! That's the point of the test.

      name = 'testhost'
      actual = runner do
        @app.start(%W(host add #{name} --groups #{group_name}))
      end

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Add host '#{name}':\n"\
        "  - Creating host '#{name}'...\n"\
        "    - OK\n"\
        "  - Adding association {host:#{name} <-> group:#{group_name}}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      desired[:STDERR] =
        "WARNING: The group '#{group_name}' doesn't exist, but will be created.\n"
        
      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups).not_to be_nil
      expect(groups.count).to eq(1)
      expect(groups[name: group_name]).not_to be_nil # i.e. not 'ungrouped'
    end

    # --------------------
    it 'HOST1 --groups ungrouped ... should abort with an error' do
      name = 'testhost'
      actual = runner do
        @app.start(%W(host add #{name} --groups ungrouped))
      end

      # Check output
      desired = { aborted: true}
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      expect(host).to be_nil
    end

    # --------------------
    it 'HOST --groups GROUP1,GROUP2 ... should add the host and '\
      'associate it with multiple groups' do
      group_names = %w(group1 group2 group3)

      name = 'testhost'
      actual = runner do
        @app.start(%W(host add #{name} --groups #{group_names.join(',')}))
      end
        
      @console.out(actual,'y')
        
      # Check output
      desired = {STDOUT: '', STDERR: ''}
      desired[:STDOUT] = 
        "Add host '#{name}':\n"\
        "  - Creating host '#{name}'...\n"\
        "    - OK\n"\
        
      group_names.each do |group|
        desired[:STDOUT] =  desired[:STDOUT] +
          "  - Adding association {host:#{name} <-> group:#{group}}...\n"\
          "    - OK\n"
        desired[:STDERR] =  desired[:STDERR] +
          "WARNING: The group '#{group}' doesn't exist, but will be created.\n"
      end
      desired[:STDOUT] = desired[:STDOUT] + 
        "  - All OK\n"\
        "Succeeded\n"

      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups.count).to eq(group_names.count)
      expect(groups[name: 'ungrouped']).to be_nil # i.e. not 'ungrouped'
      group_names.each do |group|
        expect(groups[name: group]).not_to be_nil
      end
    end

    it 'HOST --groups GROUP1,ungrouped ... should bail '\
      'with an error' do
      name = 'testhost'
      group_names = %w(group1 ungrouped)

      actual = runner do
        @app.start(%W(host add #{name} --groups #{group_names.join(',')}))
      end

      # Check output
      desired = { aborted: true}
      desired[:STDERR] =
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"

      expected(actual, desired)
    end

    it 'HOST1 HOST2 --groups GROUP1,GROUP2 ... should add multiple '\
      'hosts, associating each with multiple groups' do
      #
      group_names = %w(group1 group2 group3)
      # Note, relies on auto-generation of groups

      names = %w(host1 host2 host3)
      actual = runner do
        @app.start(%w(host add) + names + %W(--groups #{group_names.join(',')}))
      end

      # Check output
      desired = { aborted: false, STDERR: '', STDOUT: '' }
      names.each do |name|
        desired[:STDOUT] = desired[:STDOUT] + 
          "Add host '#{name}':\n"\
          "  - Creating host '#{name}'...\n"\
          "    - OK\n"
        group_names.each do |group|
          desired[:STDOUT] =  desired[:STDOUT] +
            "  - Adding association {host:#{name} <-> group:#{group}}...\n"\
            "    - OK\n"
        end
        desired[:STDOUT] = desired[:STDOUT] +
          "  - All OK\n" 
      end
      
      group_names.each do |group|
        desired[:STDERR] =  desired[:STDERR] +
          "WARNING: The group '#{group}' doesn't exist, but will be created.\n"
      end
      desired[:STDOUT] = desired[:STDOUT] + "Succeeded\n"

      #@console.out(desired,'y')
      
      expected(actual, desired)

      # Check db
      names.each do |name|
        host = @db.models[:host].find(name: name)
        expect(host).not_to be_nil
        groups = host.groups_dataset
        expect(groups.count).to eq(group_names.count)
        expect(groups[name: 'ungrouped']).to be_nil # i.e. not 'ungrouped'
        group_names.each do |group|
          expect(groups[name: group]).not_to be_nil
        end
      end
    end
  end
end
