# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/group_child_relations'

RSpec.describe Moose::Inventory::Operations::GroupChildRelations do
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

  it 'adds child groups and reports duplicate and auto-create events' do
    parent = @db.models[:group].create(name: 'parent')
    existing = @db.models[:group].create(name: 'existing')
    parent.add_child(existing)

    result = operation.add_children(
      parent_group: parent,
      parent_name: 'parent',
      child_names: %w[existing created]
    )

    expect(result.warning_count).to eq(2)
    expect(result.events.map(&:type)).to include(
      :child_association_exists,
      :child_group_missing
    )
    expect(parent.children_dataset[name: 'created']).not_to be_nil
  end

  it 'removes child groups and recursively deletes orphan groups when requested' do
    parent = @db.models[:group].create(name: 'parent')
    child = @db.models[:group].create(name: 'child')
    grandchild = @db.models[:group].create(name: 'grandchild')
    host = @db.models[:host].create(name: 'child-host')
    child.add_host(host)
    parent.add_child(child)
    child.add_child(grandchild)

    result = operation.remove_children(
      parent_group: parent,
      parent_name: 'parent',
      child_names: %w[missing child],
      delete_orphans: true
    )

    expect(result.warning_count).to eq(1)
    expect(result.events.map(&:type)).to include(
      :child_association_missing,
      :recursively_delete_orphaned_group,
      :destroying_group,
      :adding_automatic_group_to_host
    )
    expect(@db.models[:group].find(name: 'child')).to be_nil
    expect(@db.models[:group].find(name: 'grandchild')).to be_nil
    expect(host.groups_dataset[name: 'ungrouped']).not_to be_nil
  end
end
