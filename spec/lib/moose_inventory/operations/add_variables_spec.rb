# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'
require 'operations/add_variables'

RSpec.describe Moose::Inventory::Operations::AddVariables do
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

  it 'adds host variables and returns structured events without rendering output' do
    @db.models[:host].create(name: 'test1')

    actual = runner do
      @result = build_operation(:host).call(name: 'test1', vars: ['var1=val1'])
    end

    expected(actual, STDOUT: '', STDERR: '')
    expect(@result.events.map(&:type)).to eq(
      %i[entity_started retrieving_entity ok adding_variable ok entity_complete]
    )

    host = @db.models[:host].find(name: 'test1')
    expect(host.hostvars_dataset[name: 'var1'][:value]).to eq('val1')
  end

  it 'updates an existing group variable and emits an update event' do
    group = @db.models[:group].create(name: 'testgroup')
    var = @db.models[:groupvar].create(name: 'var1', value: 'old')
    group.add_groupvar(var)

    result = build_operation(:group).call(name: 'testgroup', vars: ['var1=new'])

    expect(result.events.map(&:type)).to include(:updating_existing_variable)
    expect(group.groupvars_dataset[name: 'var1'][:value]).to eq('new')
    expect(@db.models[:groupvar].count).to eq(1)
  end

  it 'emits partial progress before raising on malformed host variable input' do
    @db.models[:host].create(name: 'test1')
    emitted = []
    operation = build_operation(:host, emitter: emitted.method(:<<))

    expect do
      operation.call(name: 'test1', vars: ['broken'])
    end.to raise_error(Moose::Inventory::DB.exceptions[:moose], /Expected 'key=value'/)

    expect(emitted.map(&:type)).to eq(%i[entity_started retrieving_entity ok adding_variable])
  end
end
