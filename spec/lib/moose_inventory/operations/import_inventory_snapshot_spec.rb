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
        'web01' => { 'groups' => ['web'], 'tags' => [], 'vars' => { 'env' => 'prod' } }
      },
      'groups' => {
        'web' => { 'children' => ['blue'], 'tags' => [], 'vars' => { 'role' => 'frontend' } },
        'blue' => { 'children' => [], 'tags' => [], 'vars' => {} }
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

  it 'normalizes imported tag casing and deduplicates tags before applying' do
    snapshot = {
      version: 1,
      hosts: {
        web01: { groups: ['web'], tags: ['Prod', 'prod', ' OWNER-Platform ', ''], vars: {} }
      },
      groups: {
        web: { children: [], tags: %w[Frontend frontend], vars: {} }
      }
    }

    result = operation.call(snapshot: snapshot)

    host = @db.models[:host].find(name: 'web01')
    group = @db.models[:group].find(name: 'web')
    expect(result.associations).to eq(4)
    expect(host.tags_dataset.order(:name).map(:name)).to eq(%w[owner-platform prod])
    expect(group.tags_dataset.order(:name).map(:name)).to eq(%w[frontend])
    expect(@db.models[:tag].order(:name).map(:name)).to eq(%w[frontend owner-platform prod])
    expect(@db.models[:tag].where(name: 'Prod').count).to eq(0)

    exported = Moose::Inventory::Operations::InventorySnapshot.new(
      context: Moose::Inventory::InventoryContext.new(db: @db)
    ).export
    expect(exported.dig('hosts', 'web01', 'tags')).to eq(%w[owner-platform prod])
    expect(exported.dig('groups', 'web', 'tags')).to eq(%w[frontend])
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

  it 'rejects whitespace-only entity names before writing anything' do
    snapshot = {
      version: 1,
      hosts: { '   ' => { groups: [], vars: {} } },
      groups: {}
    }

    expect do
      operation.call(snapshot: snapshot)
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /host name cannot be empty/)

    expect(@db.models[:host].count).to eq(0)
  end

  it 'rejects duplicate normalized keys before applying the snapshot' do
    snapshot = {
      'version' => 1,
      :version => 1,
      hosts: {},
      groups: {}
    }

    expect do
      operation.call(snapshot: snapshot)
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /duplicate normalized key 'version'/)

    expect(@db.models[:host].count).to eq(0)
    expect(@db.models[:group].count).to eq(0)
  end

  it 'rejects whitespace-only variable names before writing anything' do
    snapshot = {
      version: 1,
      hosts: { web01: { groups: [], vars: { '   ' => 'prod' } } },
      groups: {}
    }

    expect do
      operation.call(snapshot: snapshot)
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /variable name cannot be empty/)

    expect(@db.models[:host].count).to eq(0)
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
