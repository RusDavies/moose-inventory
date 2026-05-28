# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/query_inventory'

RSpec.describe Moose::Inventory::Operations::QueryInventory do
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

  it 'gets host data without rendering output' do
    host = @db.models[:host].create(name: 'test1')
    host.add_group(@db.models[:group].find_or_create(name: 'ungrouped'))
    var = @db.models[:hostvar].create(name: 'foo', value: 'bar')
    host.add_hostvar(var)

    actual = runner do
      @result = operation.get_hosts(names: ['test1'])
    end

    expected(actual, STDOUT: '', STDERR: '')
    expect(@result).to eq(
      test1: {
        groups: ['ungrouped'],
        hostvars: { foo: 'bar' }
      }
    )
  end

  it 'filters listed hosts by group, tag, and variable' do
    host = @db.models[:host].create(name: 'web01')
    other = @db.models[:host].create(name: 'db01')
    group = @db.models[:group].find_or_create(name: 'web')
    tag = @db.models[:tag].find_or_create(name: 'prod')
    host.add_group(group)
    host.add_tag(tag)
    other.add_tag(tag)
    hostvar = @db.models[:hostvar].create(name: 'os', value: 'fedora')
    other_var = @db.models[:hostvar].create(name: 'os', value: 'debian')
    host.add_hostvar(hostvar)
    other.add_hostvar(other_var)

    expect(operation.list_hosts(filters: { groups: ['web'], tags: ['prod'], variables: { 'os' => 'fedora' } })).to eq(
      web01: {
        groups: ['web'],
        tags: ['prod'],
        hostvars: { os: 'fedora' }
      }
    )
  end

  it 'gets group data while omitting empty relationship collections' do
    @db.models[:group].create(name: 'group1')

    expect(operation.get_groups(names: ['group1'])).to eq(
      group1: {}
    )
  end

  it 'lists groups in ansible mode with hosts arrays and vars key' do
    group = @db.models[:group].create(name: 'group1')
    var = @db.models[:groupvar].create(name: 'foo', value: 'bar')
    group.add_groupvar(var)

    expect(operation.list_groups(ansible: true)).to eq(
      group1: {
        hosts: [],
        vars: { foo: 'bar' }
      }
    )
  end

  it 'builds ansible hostvars metadata for host listvars queries' do
    host = @db.models[:host].create(name: 'test1')
    host.add_group(@db.models[:group].find_or_create(name: 'ungrouped'))
    var = @db.models[:hostvar].create(name: 'foo', value: 'bar')
    host.add_hostvar(var)

    expect(operation.list_host_vars(names: ['test1'], ansible: true)).to eq(
      foo: 'bar',
      _meta: {
        hostvars: {
          test1: { foo: 'bar' }
        }
      }
    )
  end
end
