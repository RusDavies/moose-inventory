# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/add_groups'

RSpec.describe Moose::Inventory::Operations::AddGroups do
  before(:all) do
    @mockargs = [
      '--config', File.join(spec_root, 'config/config.yml'),
      '--format', 'yaml',
      '--env', 'test'
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

  it 'adds a group and returns structured events without rendering output' do
    actual = runner do
      @result = operation.call(names: ['testgroup'], hosts: [])
    end

    expected(actual, STDOUT: '', STDERR: '')
    expect(@result.warning_count).to eq(0)
    expect(@result.events.map(&:type)).to eq(%i[group_started creating_group ok group_complete])

    group = @db.models[:group].find(name: 'testgroup')
    expect(group).not_to be_nil
  end

  it 'reports existing groups, created hosts, duplicate associations, and ungrouped removal as events' do
    host = @db.models[:host].create(name: 'testhost')
    ungrouped = @db.models[:group].find_or_create(name: 'ungrouped')
    host.add_group(ungrouped)
    group = @db.models[:group].create(name: 'testgroup')
    group.add_host(host)

    @result = operation.call(
      names: ['testgroup'],
      hosts: %w[testhost newhost]
    )

    expect(@result.warning_count).to eq(3)
    expect(@result.events.map(&:type)).to include(
      :group_exists,
      :association_exists,
      :host_missing_created,
      :removing_automatic_group
    )
    expect(@db.models[:host].find(name: 'newhost')).not_to be_nil
    expect(host.groups_dataset[name: 'ungrouped']).to be_nil
  end
end
