# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moose::Inventory::Operations::RemoveHosts do
  before(:all) do
    mockargs = [
      '--config', File.join(spec_root, 'config/config.yml'),
      '--format', 'yaml',
      '--env', 'test'
    ]

    @config = Moose::Inventory::Config
    @config.init(mockargs)

    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?
  end

  before(:each) do
    @db.reset
    @context = Moose::Inventory::InventoryContext.new(db: @db)
    @operation = described_class.new(context: @context)
  end

  it 'removes an existing host' do
    host = @db.models[:host].create(name: 'test1')
    host.add_group(@db.models[:group].find_or_create(name: 'ungrouped'))

    result = @operation.call(names: ['test1'])

    expect(result.warning_count).to eq(0)
    expect(@db.models[:host].find(name: 'test1')).to be_nil
    expect(result.events.map(&:type)).to eq(%i[host_started retrieving_host ok destroying_host ok host_complete])
  end

  it 'returns dry-run events without deleting an existing host' do
    host = @db.models[:host].create(name: 'test1')
    host.add_group(@db.models[:group].find_or_create(name: 'ungrouped'))

    result = @operation.call(names: ['test1'], dry_run: true)

    expect(result.warning_count).to eq(0)
    expect(@db.models[:host].find(name: 'test1')).not_to be_nil
    expect(result.events.map(&:type)).to eq(%i[host_started retrieving_host ok destroying_host ok host_complete
                                               dry_run_summary])
  end
  it 'returns a warning event when the host does not exist' do
    result = @operation.call(names: ['fake'])

    expect(result.warning_count).to eq(1)
    expect(result.events.map(&:type)).to eq(%i[host_started retrieving_host host_missing missing_skipping ok
                                               host_complete])
  end
end
