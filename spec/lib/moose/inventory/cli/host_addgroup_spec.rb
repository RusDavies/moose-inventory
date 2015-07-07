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

    @host = Moose::Inventory::Cli::Host
    @app = Moose::Inventory::Cli::Application
  end

  before(:each) do
    @db.reset
  end

  #=======================
  describe 'addgroup' do
    #------------------------
    it 'Host.addgroup() should be responsive' do
      result = @host.instance_methods(false).include?(:addgroup)
      expect(result).to eq(true)
    end

    #------------------------
    it 'host addgroup <missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w(host addgroup)) # <- no group given
      end

      # Check output
      desired = { aborted: true}
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host addgroup HOST GROUP ... should abort if the host does not exist' do
      actual = runner do
        @app.start(%w(host addgroup not-a-host example))
      end

      # Check output
      desired = { aborted: true}
      desired[:STDOUT] = 
        "Associate host 'not-a-host' with groups 'example':\n"\
        "  - Retrieve host 'not-a-host'...\n"
      desired[:STDERR] = 
        "An error occurred during a transaction, any changes have been rolled back.\n"\
        "ERROR: The host 'not-a-host' was not found in the database.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'host addgroup HOST GROUP ... should add the host to an existing group' do
      # 1. Should add the host to the group
      # 2. Should remove the host from the 'ungrouped' automatic group
      
      name = 'test1'
      group_name = 'testgroup1'

      runner { @app.start(%W(host add #{name})) }
      @db.models[:group].create(name: group_name)

      actual = runner { @app.start(%W(host addgroup #{name} #{group_name} )) }

      # rubocop:disable Metrics/LineLength
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Associate host '#{name}' with groups '#{group_name}':\n"\
        "  - Retrieve host '#{name}'...\n"\
        "    - OK\n"\
        "  - Add association {host:#{name} <-> group:#{group_name}}...\n"\
        "    - OK\n"\
        "  - Remove automatic association {host:#{name} <-> group:ungrouped}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      expected(actual, desired)
      # rubocop:enable Metrics/LineLength

      # We should have the correct group associations
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: group_name]).not_to be_nil
      expect(groups[name: 'ungrouped']).to be_nil # redundant, but for clarity!      
    end

    #------------------------
    it 'HOST \'ungrouped\' ... should abort with an error' do
      
      name = 'test1'
      group_name = 'ungrouped'
    
      runner { @app.start(%W(host add #{name})) }
    
      actual = runner { @app.start(%W(host addgroup #{name} #{group_name} )) }
    
      desired = { aborted: true}
      desired[:STDERR] = 
        "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)
    end 
    
    #------------------------
    it 'HOST GROUP ... should add the host to an group, creating the group if necessary' do
      name = 'test1'
      group_name = 'testgroup1'

      runner { @app.start(%W(host add #{name})) }

      # DON'T CREATE THE GROUP! That's the point of the test. ;o)

      actual = runner { @app.start(%W(host addgroup #{name} #{group_name} )) }

      # Check output
      desired = { aborted: false}
      desired[:STDOUT] = 
        "Associate host '#{name}' with groups '#{group_name}':\n"\
        "  - Retrieve host '#{name}'...\n"\
        "    - OK\n"\
        "  - Add association {host:#{name} <-> group:#{group_name}}...\n"\
        "    - Group does not exist, creating now...\n"\
        "      - OK\n"\
        "    - OK\n"\
        "  - Remove automatic association {host:#{name} <-> group:ungrouped}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      desired[:STDERR] =
        "WARNING: Group '#{group_name}' does not exist and will be created." 
      expected(actual, desired)

      # Check db          
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups.count).to eq(1)
      expect(groups[name: group_name]).not_to be_nil
      expect(groups[name: 'ungrouped']).to be_nil # redundant, but for clarity!      
    end
    
    #------------------------
     it 'HOST GROUP ... should skip associations that already '\
       ' exist, but raise a warning.' do
       name = 'test1'
       group_name = 'testgroup1'
    
       runner { @app.start(%W(host add #{name})) }
    
       # DON'T CREATE THE GROUP! That's the point of the test. ;o)
    
       # Run once to make the association
       runner { @app.start(%W(host addgroup #{name} #{group_name} )) }
         
       # Run again, to prove expected result
       actual = runner { @app.start(%W(host addgroup #{name} #{group_name} )) }
    
       # Check output
       # Note: This time, we don't expect to see any messages about 
       # dissociation from 'ungrouped'
       desired = { aborted: false}
       desired[:STDOUT] = 
         "Associate host '#{name}' with groups '#{group_name}':\n"\
         "  - Retrieve host \'#{name}\'...\n"\
         "    - OK\n"\
         "  - Add association {host:#{name} <-> group:#{group_name}}...\n"\
         "    - Already exists, skipping.\n"\
         "    - OK\n"\
         "  - All OK\n"\
         "Succeeded\n"
       desired[:STDERR] = "WARNING: Association {host:#{name} <-> group:#{group_name}} already exists, skipping."
       expected(actual, desired)
    
       # Check db          
       host = @db.models[:host].find(name: name)
       groups = host.groups_dataset
       expect(groups.count).to eq(1)
       expect(groups[name: group_name]).not_to be_nil
       expect(groups[name: 'ungrouped']).to be_nil # redundant, but for clarity!      
     end    

    #------------------------
    it 'host addgroup GROUP1 GROUP1 ... should add the host to'\
      ' multiple groups at once' do
      name = 'test1'
      group_names = %w(group1 group2 group3)

      runner { @app.start(%W(host add #{name})) }

      actual = runner { @app.start(%W(host addgroup #{name}) + group_names) }

      # Check output
      desired = { aborted: false, STDERR: ''}
      desired[:STDOUT] =
        "Associate host '#{name}' with groups '#{group_names.join(',')}':\n"\
        "  - Retrieve host '#{name}'...\n"\
        "    - OK\n"
      group_names.each do |group|
        desired[:STDOUT] = desired[:STDOUT] + 
          "  - Add association {host:#{name} <-> group:#{group}}...\n"\
          "    - Group does not exist, creating now...\n"\
          "      - OK\n"\
          "    - OK\n"

        desired[:STDERR] = desired[:STDERR] +  
          "WARNING: Group '#{group}' does not exist and will be created." 
      end
      desired[:STDOUT]  = desired[:STDOUT]  + 
        "  - Remove automatic association {host:#{name} <-> group:ungrouped}...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded\n"
      expected(actual, desired)
      

      # We should have group associations
      host = @db.models[:host].find(name: name)
      groups = host.groups_dataset
      expect(groups).not_to be_nil

      # There should be 3 relationships, but not with 'ungrouped'
      expect(groups.count).to eq(3)
      group_names.each do |group|
        expect(groups[name: group]).not_to be_nil
      end
      expect(groups[name: 'ungrouped']).to be_nil
    end
  end
end
