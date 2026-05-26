require 'spec_helper'

RSpec.describe Moose::Inventory::Operations::AddHosts do
  before(:all) do
    @mockargs = [
      '--config', File.join(spec_root, 'config/config.yml'),
      '--format', 'yaml',
      '--env', 'test',
    ]

    Moose::Inventory::Config.init(@mockargs)
    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?
  end

  before(:each) do
    @db.reset
  end

  def operation
    described_class.new(
      context: Moose::Inventory::InventoryContext.new(db: @db)
    )
  end

  describe '#call' do
    it 'adds a host and returns structured events without rendering output' do
      actual = runner do
        @result = operation.call(names: ['testhost'], groups: [])
      end

      expected(actual, STDOUT: '', STDERR: '')
      expect(@result.events.map(&:type)).to eq(
        %i[host_started creating_host ok adding_automatic_group ok host_complete]
      )
      expect(@result.events[0].payload).to eq(name: 'testhost')
      expect(@result.events[3].payload).to eq(host: 'testhost', group: 'ungrouped')

      host = @db.models[:host].find(name: 'testhost')
      expect(host).not_to be_nil
      expect(host.groups_dataset[name: 'ungrouped']).not_to be_nil
    end

    it 'reports existing hosts, missing groups, and duplicate associations as events' do
      host = @db.models[:host].create(name: 'testhost')
      group = @db.models[:group].create(name: 'existinggroup')
      host.add_group(group)

      @result = operation.call(
        names: ['testhost'],
        groups: %w[existinggroup missinggroup]
      )

      expect(@result.events.map(&:type)).to include(
        :host_exists,
        :association_exists,
        :group_missing_created
      )
      expect(@result.events.find { |event| event.type == :host_exists }.payload).to eq(name: 'testhost')
      expect(@result.events.find { |event| event.type == :association_exists }.payload).to eq(
        host: 'testhost',
        group: 'existinggroup'
      )
      expect(@db.models[:group].find(name: 'missinggroup')).not_to be_nil
    end
  end
end
