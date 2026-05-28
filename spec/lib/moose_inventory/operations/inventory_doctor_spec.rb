# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'inventory_context'
require 'operations/inventory_doctor'

RSpec.describe Moose::Inventory::Operations::InventoryDoctor do
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

  def doctor(config: Moose::Inventory::Config)
    described_class.new(context: Moose::Inventory::InventoryContext.new(db: @db), config: config)
  end

  it 'reports ok when the inventory and config have no findings' do
    web = @db.models[:group].create(name: 'web')
    host = @db.models[:host].create(name: 'web01')
    host.add_group(web)

    report = doctor.call

    expect(report[:ok]).to eq(true)
    expect(report[:issues]).to eq([])
  end

  it 'detects inventory health findings' do
    ungrouped = @db.models[:group].create(name: 'ungrouped')
    orphan = @db.models[:group].create(name: 'orphan')
    duplicate = @db.models[:group].create(name: 'or-phan')
    parent = @db.models[:group].create(name: 'parent')
    child = @db.models[:group].create(name: 'child')
    host = @db.models[:host].create(name: 'lonely')
    bad_var = @db.models[:hostvar].create(name: '', value: 'oops')
    host.add_group(ungrouped)
    host.add_hostvar(bad_var)
    parent.add_child(child)
    child.add_child(parent)

    report = doctor.call
    @db.db[:groups_groups].delete

    expect(report[:ok]).to eq(false)
    expect(report[:issues].map { |issue| issue[:id] }).to include(
      'host_only_in_ungrouped',
      'orphaned_group',
      'empty_group',
      'duplicateish_group_names',
      'invalid_variable_shape',
      'circular_group_relationship'
    )
    expect(report[:issues].map { |issue| issue[:subject] }).to include(orphan.name)
    expect(report[:issues].map { |issue| issue[:subject] }).to include([duplicate.name, orphan.name].sort)
  end

  it 'detects plaintext password configuration' do
    config = instance_double('Config', db_settings: { adapter: 'mysql', password: 'secret' })

    report = doctor(config: config).call

    expect(report[:issues].map { |issue| issue[:id] }).to include('plaintext_password_config')
  end
end
# rubocop:enable Metrics/BlockLength
