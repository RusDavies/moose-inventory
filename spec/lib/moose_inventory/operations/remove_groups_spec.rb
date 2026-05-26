# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/remove_groups'

RSpec.describe Moose::Inventory::Operations::RemoveGroups do
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

  it 'reports missing groups as warnings' do
    result = operation.call(names: ['missing'], recursive: false)

    expect(result.warning_count).to eq(1)
    expect(result.events.map(&:type)).to include(:group_missing)
  end

  it 'removes groups and recursively cleans orphaned children when requested' do
    parent = @db.models[:group].create(name: 'parent')
    child = @db.models[:group].create(name: 'child')
    host = @db.models[:host].create(name: 'child-host')
    child.add_host(host)
    parent.add_child(child)

    result = operation.call(names: ['parent'], recursive: true)

    expect(result.warning_count).to eq(0)
    expect(result.events.map(&:type)).to include(
      :removing_child_association,
      :recursively_delete_orphaned_group,
      :adding_automatic_group_to_host,
      :destroying_group
    )
    expect(@db.models[:group].find(name: 'parent')).to be_nil
    expect(@db.models[:group].find(name: 'child')).to be_nil
    expect(host.groups_dataset[name: 'ungrouped']).not_to be_nil
  end
end
