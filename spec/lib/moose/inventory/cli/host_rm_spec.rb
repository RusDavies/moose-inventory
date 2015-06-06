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

  #======================
  describe 'rm' do
    #---------------
    it 'Host.rm() should be responsive' do
      result = @host.instance_methods(false).include?(:rm)
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

    #---------------
    it 'HOST ... should warn about hosts that don\'t exist' do
      # Rationale:
      # The request implies the desired state is that the host is not present
      # If the host is not present, for whatever reason, then the desired state
      # already exists.

      # no items in the db
      name = "fake"
      actual = runner {  @app.start(%W(host rm #{name})) }

      desired = {}
      desired[:STDOUT] =
        "Remove host '#{name}':\n"\
        "  - Retrieve host '#{name}'...\n"\
        "    - No such host, skipping.\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Host '#{name}' does not exist, skipping.\n"

      expected(actual, desired)
    end

    #---------------
    it 'HOST ... should remove a host' do
      name = 'test1'
      @db.models[:host].create(name: name)

      actual = runner { @app.start(%W(host rm #{name})) }

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Remove host '#{name}':\n"\
        "  - Retrieve host '#{name}'...\n"\
        "    - OK\n"\
        "  - Destroy host '#{name}'...\n"\
        "    - OK\n"\
        "  - All OK\n"\
        "Succeeded.\n"
        
      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      expect(host).to be_nil
    end

    #---------------
    it 'HOST1 HOST2 ... should remove multiple hosts' do
      names = %w(host1 host2 host3)
      names.each do |name|
        @db.models[:host].create(name: name)
      end

      actual = runner { @app.start(%w(host rm) + names) }

      # Check output
      desired = { aborted: false, STDERR: '', STDOUT: '' }
      names.each do |name|
        desired[:STDOUT] = desired[:STDOUT] +
          "Remove host '#{name}':\n"\
          "  - Retrieve host '#{name}'...\n"\
          "    - OK\n"\
          "  - Destroy host '#{name}'...\n"\
          "    - OK\n"\
          "  - All OK\n"
      end
      desired[:STDOUT] = desired[:STDOUT] + 
        "Succeeded.\n"
      expected(actual, desired)

      # Check db
      hosts = @db.models[:host].all
      expect(hosts.count).to eq(0)
    end
  end
end
