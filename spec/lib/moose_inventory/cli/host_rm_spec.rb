# frozen_string_literal: true

require 'spec_helper'

# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Host do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Host, command_ivar: :@host)
  end

  before(:each) do
    reset_cli_harness
  end

  #======================
  describe 'rm' do
    #---------------
    it 'Host.rm() should be responsive' do
      result = @host.method_defined?(:rm, false)
      expect(result).to eq(true)
    end

    #---------------
    it '<missing argument> ... should abort with an error' do
      actual = runner { @app.start(%w[host rm]) }

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
      name = 'fake'
      actual = runner { @app.start(%W[host rm #{name}]) }

      desired = {}
      desired[:STDOUT] =
        "Remove host '#{name}':\n  " \
        "- Retrieve host '#{name}'...\n    " \
        "- No such host, skipping.\n    " \
        "- OK\n  " \
        "- All OK\n" \
        "Succeeded, with warnings.\n"
      desired[:STDERR] =
        "WARNING: Host '#{name}' does not exist, skipping.\n"

      expected(actual, desired)
    end

    #---------------
    it 'HOST ... should remove a host' do
      name = 'test1'
      @db.models[:host].create(name: name)

      actual = runner { @app.start(%W[host rm #{name}]) }

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Remove host '#{name}':\n  " \
        "- Retrieve host '#{name}'...\n    " \
        "- OK\n  " \
        "- Destroy host '#{name}'...\n    " \
        "- OK\n  " \
        "- All OK\n" \
        "Succeeded.\n"

      expected(actual, desired)

      # Check db
      host = @db.models[:host].find(name: name)
      expect(host).to be_nil
    end

    #---------------
    it 'HOST --dry-run should show planned removal without deleting the host' do
      name = 'test1'
      @db.models[:host].create(name: name)

      actual = runner { @app.start(%W[host rm #{name} --dry-run]) }

      desired = {}
      desired[:STDOUT] =
        "Remove host '#{name}':\n  " \
        "- Retrieve host '#{name}'...\n    " \
        "- OK\n  " \
        "- Destroy host '#{name}'...\n    " \
        "- OK\n  " \
        "- All OK\n" \
        "Dry run complete. No changes applied.\n" \
        "Succeeded.\n"

      expected(actual, desired)
      expect(@db.models[:host].find(name: name)).not_to be_nil
    end
    #---------------
    it 'HOST1 HOST2 ... should remove multiple hosts' do
      names = %w[host1 host2 host3]
      names.each do |name|
        @db.models[:host].create(name: name)
      end

      actual = runner { @app.start(%w[host rm] + names) }

      # Check output
      desired = { aborted: false, STDERR: '', STDOUT: '' }
      names.each do |name|
        desired[:STDOUT] = desired[:STDOUT] +
                           "Remove host '#{name}':\n  " \
                           "- Retrieve host '#{name}'...\n    " \
                           "- OK\n  " \
                           "- Destroy host '#{name}'...\n    " \
                           "- OK\n  " \
                           "- All OK\n"
      end
      desired[:STDOUT] = "#{desired[:STDOUT]}Succeeded.\n"
      expected(actual, desired)

      # Check db
      hosts = @db.models[:host].all
      expect(hosts.count).to eq(0)
    end
  end
end
