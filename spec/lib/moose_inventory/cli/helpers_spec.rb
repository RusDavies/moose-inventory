# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Moose::Inventory::Cli::Helpers do
  subject(:helper) { helper_class.new }

  let(:helper_class) do
    Class.new do
      include Moose::Inventory::Cli::Helpers
    end
  end

  let(:inventory_context) { instance_double(Moose::Inventory::InventoryContext) }
  let(:automatic_group) { instance_double('AutomaticGroup') }

  before do
    helper.instance_variable_set(:@inventory_context, inventory_context)
    allow(inventory_context).to receive(:automatic_group).and_return(automatic_group)
  end

  describe 'small helper methods' do
    it 'checks whether an association dataset contains a named record' do
      dataset = instance_double('Dataset')

      expect(helper.send(:association_exists?, nil, 'alpha')).to eq(false)
      allow(dataset).to receive(:[]).with(name: 'alpha').and_return(nil)
      expect(helper.send(:association_exists?, dataset, 'alpha')).to eq(false)
      allow(dataset).to receive(:[]).with(name: 'beta').and_return({ name: 'beta' })
      expect(helper.send(:association_exists?, dataset, 'beta')).to eq(true)
    end

    it 'converts exceptions to strings' do
      expect(helper.send(:exception_to_s, RuntimeError.new('boom'))).to eq('boom')
    end

    it 'returns the automatic group through the inventory context' do
      expect(helper.send(:automatic_group)).to eq(automatic_group)
    end
  end

  describe 'run_group_relation_transaction' do
    it 'prints the heading and success marker for a successful transaction' do
      allow(Moose::Inventory::DB).to receive(:transaction).and_yield
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(2, '- all OK')

      result = nil
      actual = runner do
        result = helper.send(:run_group_relation_transaction, heading: 'Heading') { :done }
      end

      expect(result).to eq(:done)
      expected(actual, aborted: false, STDOUT: "Heading\n", STDERR: '')
    end

    it 'aborts with the Moose exception message when no custom handler is supplied' do
      error = Moose::Inventory::DB::MooseDBException.new('boom')
      allow(Moose::Inventory::DB).to receive(:transaction).and_raise(error)
      allow(Moose::Inventory::DB).to receive(:exceptions).and_return({ moose: Moose::Inventory::DB::MooseDBException })

      actual = runner do
        helper.send(:run_group_relation_transaction, heading: 'Heading') { :done }
      end

      expected(actual, aborted: true, STDOUT: '', STDERR: "ERROR: boom\n")
    end

    it 'uses the custom Moose exception handler when provided' do
      error = Moose::Inventory::DB::MooseDBException.new('boom')
      allow(Moose::Inventory::DB).to receive(:transaction).and_raise(error)
      allow(Moose::Inventory::DB).to receive(:exceptions).and_return({ moose: Moose::Inventory::DB::MooseDBException })

      actual = runner do
        helper.send(
          :run_group_relation_transaction,
          heading: 'Heading',
          on_error: ->(e) { "wrapped #{e.message}" }
        ) { :done }
      end

      expected(actual, aborted: true, STDOUT: '', STDERR: "ERROR: wrapped boom\n")
    end
  end

  describe 'automatic-group helpers' do
    it 'removes the automatic group from a host when present' do
      host = instance_double('Host')
      dataset = instance_double('Dataset')
      ungrouped = instance_double('Group')
      allow(host).to receive(:groups_dataset).and_return(dataset)
      allow(dataset).to receive(:[]).with(name: 'ungrouped').and_return(ungrouped)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(2, 'remove auto')
      expect(host).to receive(:remove_group).with(ungrouped)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(4, '- OK')

      helper.send(:remove_automatic_group_from_host, host, indent: 2, message: 'remove auto')
    end

    it 'does nothing when the automatic group is not present' do
      host = instance_double('Host')
      dataset = instance_double('Dataset')
      allow(host).to receive(:groups_dataset).and_return(dataset)
      allow(dataset).to receive(:[]).with(name: 'ungrouped').and_return(nil)

      expect(Moose::Inventory::Cli::Formatter).not_to receive(:puts)
      expect(host).not_to receive(:remove_group)

      helper.send(:remove_automatic_group_from_host, host, indent: 2, message: 'remove auto')
    end

    it 'adds the automatic group when the last non-automatic group is removed' do
      host = instance_double('Host')
      dataset = instance_double('Dataset', count: 1)
      allow(host).to receive(:groups_dataset).and_return(dataset)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(2, 'add auto')
      expect(host).to receive(:add_group).with(automatic_group)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(4, '- OK')

      helper.send(:add_automatic_group_to_host_if_last_group, host, indent: 2, message: 'add auto')
    end

    it 'adds the automatic group when a host has no groups' do
      host = instance_double('Host')
      dataset = instance_double('Dataset', count: 0)
      allow(host).to receive(:groups_dataset).and_return(dataset)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(2, 'add auto')
      expect(host).to receive(:add_group).with(automatic_group)
      expect(Moose::Inventory::Cli::Formatter).to receive(:puts).with(4, '- OK')

      helper.send(:add_automatic_group_to_host_if_no_groups, host, indent: 2, message: 'add auto')
    end

    it 'does nothing when the group count does not match the requested threshold' do
      host = instance_double('Host')
      dataset = instance_double('Dataset', count: 2)
      allow(host).to receive(:groups_dataset).and_return(dataset)

      expect(Moose::Inventory::Cli::Formatter).not_to receive(:puts)
      expect(host).not_to receive(:add_group)

      helper.send(:add_automatic_group_to_host_if_group_count, host, 1, indent: 2, message: 'add auto')
    end
  end
end
# rubocop:enable Metrics/BlockLength
