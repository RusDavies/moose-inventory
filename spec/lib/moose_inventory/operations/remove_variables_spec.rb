# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/remove_variables'

RSpec.describe Moose::Inventory::Operations::RemoveVariables do
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

  def build_operation(entity_type, emitter: nil)
    described_class.new(
      context: Moose::Inventory::InventoryContext.new(db: @db),
      entity_type: entity_type,
      emitter: emitter
    )
  end

  it 'removes host variables and returns structured events without rendering output' do
    host = @db.models[:host].create(name: 'test1')
    var = @db.models[:hostvar].create(name: 'var1', value: 'val1')
    host.add_hostvar(var)

    actual = runner do
      @result = build_operation(:host).call(name: 'test1', vars: ['var1'])
    end

    expected(actual, STDOUT: '', STDERR: '')
    expect(@result.events.map(&:type)).to eq(
      %i[entity_started retrieving_entity ok removing_variable ok entity_complete]
    )
    expect(host.hostvars_dataset.count).to eq(0)
    expect(@db.models[:hostvar].count).to eq(0)
  end

  it 'accepts group variable removal by key=value syntax and removes the record' do
    group = @db.models[:group].create(name: 'testgroup')
    var = @db.models[:groupvar].create(name: 'var1', value: 'val1')
    group.add_groupvar(var)

    build_operation(:group).call(name: 'testgroup', vars: ['var1=val1'])

    expect(group.groupvars_dataset.count).to eq(0)
    expect(@db.models[:groupvar].count).to eq(0)
  end

  it 'emits partial progress before raising on malformed group variable removal input' do
    @db.models[:group].create(name: 'testgroup')
    emitted = []
    operation = build_operation(:group, emitter: emitted.method(:<<))

    expect do
      operation.call(name: 'testgroup', vars: ['=broken'])
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /Expected 'key' or 'key=value'/)

    expect(emitted.map(&:type)).to eq(%i[entity_started retrieving_entity ok removing_variable])
  end
end
