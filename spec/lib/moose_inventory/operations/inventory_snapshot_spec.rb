# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'inventory_context'
require 'operations/inventory_snapshot'

RSpec.describe Moose::Inventory::Operations::InventorySnapshot do
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

  it 'exports hosts, groups, variables, and child relationships in canonical order' do
    host = @db.models[:host].create(name: 'web01')
    group = @db.models[:group].create(name: 'web')
    child = @db.models[:group].create(name: 'blue')
    hostvar = @db.models[:hostvar].create(name: 'env', value: 'prod')
    groupvar = @db.models[:groupvar].create(name: 'role', value: 'frontend')
    host.add_group(group)
    host.add_hostvar(hostvar)
    group.add_child(child)
    group.add_groupvar(groupvar)

    snapshot = described_class.new(context: Moose::Inventory::InventoryContext.new(db: @db)).export

    expect(snapshot).to eq(
      'version' => 1,
      'hosts' => {
        'web01' => { 'groups' => ['web'], 'tags' => [], 'vars' => { 'env' => 'prod' } }
      },
      'groups' => {
        'blue' => { 'children' => [], 'tags' => [], 'vars' => {} },
        'web' => { 'children' => ['blue'], 'tags' => [], 'vars' => { 'role' => 'frontend' } }
      }
    )
  end
end
# rubocop:enable Metrics/BlockLength
