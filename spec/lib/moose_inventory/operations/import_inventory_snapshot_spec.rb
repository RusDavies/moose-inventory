# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'inventory_context'
require 'operations/inventory_snapshot'
require 'operations/import_inventory_snapshot'

RSpec.describe Moose::Inventory::Operations::ImportInventorySnapshot do
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
    described_class.new(context: Moose::Inventory::InventoryContext.new(db: @db))
  end

  it 'imports a validated snapshot transactionally' do
    snapshot = {
      'version' => 1,
      'hosts' => {
        'web01' => { 'groups' => ['web'], 'vars' => { 'env' => 'prod' } }
      },
      'groups' => {
        'web' => { 'children' => ['blue'], 'vars' => { 'role' => 'frontend' } },
        'blue' => { 'children' => [], 'vars' => {} }
      }
    }

    result = operation.call(snapshot: snapshot)

    expect(result.created_hosts).to eq(1)
    expect(result.created_groups).to eq(2)
    expect(result.updated_variables).to eq(2)
    expect(result.associations).to eq(2)
    host = @db.models[:host].find(name: 'web01')
    group = @db.models[:group].find(name: 'web')
    expect(host.groups_dataset[name: 'web']).not_to be_nil
    expect(host.hostvars_dataset[name: 'env'][:value]).to eq('prod')
    expect(group.children_dataset[name: 'blue']).not_to be_nil
    expect(group.groupvars_dataset[name: 'role'][:value]).to eq('frontend')
  end

  it 'rejects unknown group references before writing anything' do
    snapshot = {
      version: 1,
      hosts: { web01: { groups: ['missing'], vars: {} } },
      groups: {}
    }

    expect do
      operation.call(snapshot: snapshot)
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /references unknown group 'missing'/)

    expect(@db.models[:host].count).to eq(0)
    expect(@db.models[:group].count).to eq(0)
  end

  it 'rejects circular group hierarchies before writing anything' do
    snapshot = {
      version: 1,
      hosts: {},
      groups: {
        parent: { children: ['child'], vars: {} },
        child: { children: ['parent'], vars: {} }
      }
    }

    expect do
      operation.call(snapshot: snapshot)
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /contains a cycle/)

    expect(@db.models[:group].count).to eq(0)
  end
end
# rubocop:enable Metrics/BlockLength
