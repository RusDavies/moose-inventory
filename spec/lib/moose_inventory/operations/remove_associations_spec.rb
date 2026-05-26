# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/remove_associations'

RSpec.describe Moose::Inventory::Operations::RemoveAssociations do
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

  it 'removes groups from a host and reports missing associations and ungrouped reattachment' do
    host = @db.models[:host].create(name: 'host1')
    group = @db.models[:group].create(name: 'group1')
    other = @db.models[:group].create(name: 'group2')
    host.add_group(group)
    host.add_group(other)

    result = operation.host_from_groups(
      host: host,
      host_name: 'host1',
      group_names: %w[group1 missing group2]
    )

    expect(result.warning_count).to eq(1)
    expect(result.events.map(&:type)).to include(
      :host_group_association_missing,
      :adding_automatic_group
    )
    expect(host.groups_dataset[name: 'group1']).to be_nil
    expect(host.groups_dataset[name: 'group2']).to be_nil
    expect(host.groups_dataset[name: 'ungrouped']).not_to be_nil
  end

  it 'removes hosts from a group and reports missing associations and ungrouped reattachment' do
    group = @db.models[:group].create(name: 'group1')
    host1 = @db.models[:host].create(name: 'host1')
    host2 = @db.models[:host].create(name: 'host2')
    extra = @db.models[:group].create(name: 'extra')
    host2.add_group(extra)
    group.add_host(host1)
    group.add_host(host2)

    result = operation.group_from_hosts(
      group: group,
      group_name: 'group1',
      host_names: %w[host1 missing host2]
    )

    expect(result.warning_count).to eq(1)
    expect(result.events.map(&:type)).to include(
      :group_host_association_missing,
      :adding_automatic_group
    )
    expect(group.hosts_dataset[name: 'host1']).to be_nil
    expect(group.hosts_dataset[name: 'host2']).to be_nil
    expect(host1.groups_dataset[name: 'ungrouped']).not_to be_nil
    expect(host2.groups_dataset[name: 'ungrouped']).to be_nil
  end
end
