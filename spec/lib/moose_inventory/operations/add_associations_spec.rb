# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/add_associations'

RSpec.describe Moose::Inventory::Operations::AddAssociations do
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

  it 'adds groups to an existing host and reports creation/duplicate events' do
    host = @db.models[:host].create(name: 'host1')
    ungrouped = @db.models[:group].find_or_create(name: 'ungrouped')
    host.add_group(ungrouped)
    existing_group = @db.models[:group].create(name: 'existing')
    host.add_group(existing_group)

    result = operation.host_to_groups(
      host: host,
      host_name: 'host1',
      group_names: %w[existing created]
    )

    expect(result.warning_count).to eq(2)
    expect(result.events.map(&:type)).to include(
      :host_group_association_exists,
      :group_missing_created,
      :removing_automatic_group
    )
    expect(host.groups_dataset[name: 'created']).not_to be_nil
    expect(host.groups_dataset[name: 'ungrouped']).to be_nil
  end

  it 'adds hosts to an existing group and reports creation/duplicate events' do
    group = @db.models[:group].create(name: 'group1')
    duplicate_host = @db.models[:host].create(name: 'host1')
    existing_host = @db.models[:host].create(name: 'host3')
    ungrouped = @db.models[:group].find_or_create(name: 'ungrouped')
    duplicate_host.add_group(ungrouped)
    existing_host.add_group(ungrouped)
    group.add_host(duplicate_host)

    result = operation.group_to_hosts(
      group: group,
      group_name: 'group1',
      host_names: %w[host1 host2 host3]
    )

    expect(result.warning_count).to eq(2)
    expect(result.events.map(&:type)).to include(
      :group_host_association_exists,
      :host_missing_created,
      :removing_automatic_group
    )
    expect(group.hosts_dataset[name: 'host2']).not_to be_nil
    expect(existing_host.groups_dataset[name: 'ungrouped']).to be_nil
  end
end
