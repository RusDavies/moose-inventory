# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Group do
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config: File.join(spec_root, 'config/config.yml'),
      format: 'yaml',
      env: 'test'
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
  describe 'rmchild' do
    #------------------------
    it 'Group.rmchild() should be responsive' do
      result = @group.method_defined?(:rmchild, false)
      expect(result).to eq(true)
    end

    #------------------------
    it '<missing args> ... should abort with an error' do
      actual = runner  do
        @app.start(%w[group addchild])
      end

      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Wrong number of arguments, 0 for 2 or more.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'ungrouped ... should abort with an error' do
      parent_name = 'ungrouped'
      child_name = 'fake'

      actual = runner do
        @app.start(%W[group addchild #{parent_name} #{child_name}])
      end

      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)

      ############################
      # Should work the other way round too, when the child in the ungrouped item
      parent_name = 'fake'
      child_name = 'ungrouped'

      actual = runner do
        @app.start(%W[group rmchild #{parent_name} #{child_name} --yes])
      end

      # @console.out(actual, 'y')

      # Check output
      desired = { aborted: true }
      desired[:STDERR] = "ERROR: Cannot manually manipulate the automatic group 'ungrouped'.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP CHILDGROUP  ... should abort if GROUP does not exist' do
      pname = 'parent_group'
      cname = 'child group'

      actual = runner do
        @app.start(%W[group rmchild #{pname} #{cname} --yes])
      end

      # @console.out(actual, 'y')
      # Check output
      desired = { aborted: true }
      desired[:STDOUT] =
        "Dissociate parent group '#{pname}' from child group(s) '#{cname}':\n  " \
        "- retrieve group '#{pname}'...\n"
      desired[:STDERR] =
        "ERROR: The group '#{pname}' does not exist.\n" \
        "An error occurred during a transaction, any changes have been rolled back.\n"
      expected(actual, desired)
    end

    #------------------------
    it 'GROUP CHILDGROUP  ... should succeed with warnings if CHILDGROUP is not associated' do
      pname = 'parent_group'
      cname = 'child group'

      runner { @app.start(%W[group add #{pname} #{cname}]) }

      actual = runner do
        @app.start(%W[group rmchild #{pname} #{cname} --yes])
      end

      # @console.out(actual, 'y')

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Dissociate parent group '#{pname}' from child group(s) '#{cname}':\n  " \
        "- retrieve group '#{pname}'...\n    " \
        "- OK\n  " \
        "- remove association {group:#{pname} <-> group:#{cname}}...\n    " \
        "- doesn't exist, skipping.\n    " \
        "- OK\n  " \
        "- all OK\n" \
        "Succeeded, with warnings.\n"

      desired[:STDERR] =
        "WARNING: Association {group:#{pname} <-> group:#{cname}} does not exist, skipping.\n"

      expected(actual, desired)
    end

    #------------------------
    it 'GROUP CHILDGROUP  ... should succeed without warnings if CHILDGROUP is associated' do
      pname = 'parent_group'
      cname = 'child group'

      runner { @app.start(%W[group add #{pname} #{cname}]) }
      runner { @app.start(%W[group addchild #{pname} #{cname}]) }

      actual = runner do
        @app.start(%W[group rmchild #{pname} #{cname} --yes])
      end

      # @console.out(actual, 'y')

      # Check output
      desired = {}
      desired[:STDOUT] =
        "Dissociate parent group '#{pname}' from child group(s) '#{cname}':\n  " \
        "- retrieve group '#{pname}'...\n    " \
        "- OK\n  " \
        "- remove association {group:#{pname} <-> group:#{cname}}...\n    " \
        "- OK\n  " \
        "- all OK\n" \
        "Succeeded.\n"

      expected(actual, desired)
    end

    #------------------------
    it 'GROUP CHILDGROUP --delete-orphans --dry-run should not remove or delete groups' do
      runner { @app.start(%w[group add parent]) }
      runner { @app.start(%w[group add child --hosts child-host]) }
      runner { @app.start(%w[group addchild parent child]) }

      actual = runner do
        @app.start(%w[group rmchild --delete-orphans parent child --dry-run])
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDOUT]).to include('Dry run complete. No changes applied.')
      expect(actual[:STDOUT]).to include("- Recursively delete orphaned group 'child'...
")
      parent = @db.models[:group].find(name: 'parent')
      expect(parent.children_dataset[name: 'child']).not_to be_nil
      expect(@db.models[:group].find(name: 'child')).not_to be_nil
      host = @db.models[:host].find(name: 'child-host')
      expect(host.groups_dataset[name: 'ungrouped']).to be_nil
    end

    #------------------------
    it 'GROUP CHILDGROUP --delete-orphans ... should delete orphaned child groups recursively' do
      runner { @app.start(%w[group add parent]) }
      runner { @app.start(%w[group add child --hosts child-host]) }
      runner { @app.start(%w[group add grandchild]) }
      runner { @app.start(%w[group addchild parent child]) }
      runner { @app.start(%w[group addchild child grandchild]) }

      actual = runner do
        @app.start(%w[group rmchild --delete-orphans parent child --yes])
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDOUT]).to include("- Recursively delete orphaned group 'child'...\n")
      expect(actual[:STDOUT]).to include("- Recursively delete orphaned group 'grandchild'...\n")

      expect(@db.models[:group].find(name: 'parent')).not_to be_nil
      %w[child grandchild].each do |name|
        expect(@db.models[:group].find(name: name)).to be_nil
      end

      host = @db.models[:host].find(name: 'child-host')
      expect(host.groups_dataset[name: 'ungrouped']).not_to be_nil
    end

    #------------------------
    it 'GROUP CHILDGROUP --delete-orphans ... should preserve child groups with another parent' do
      runner { @app.start(%w[group add parent other-parent]) }
      runner { @app.start(%w[group addchild parent child]) }
      runner { @app.start(%w[group addchild other-parent child]) }

      actual = runner do
        @app.start(%w[group rmchild --delete-orphans parent child --yes])
      end

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)

      child = @db.models[:group].find(name: 'child')
      expect(child).not_to be_nil
      expect(child.parents_dataset[name: 'parent']).to be_nil
      expect(child.parents_dataset[name: 'other-parent']).not_to be_nil
    end
  end
end
# rubocop:enable Metrics/BlockLength
