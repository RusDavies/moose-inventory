# frozen_string_literal: true

require 'spec_helper'
require 'cli/factory'
require 'operations/query_inventory'

RSpec.describe Moose::Inventory::Cli::Factory do
  let(:context) { instance_double('InventoryContext') }
  subject(:factory) { described_class.new(context: context) }

  it 'builds operations with the shared context' do
    operation_class = class_double('OperationClass')
    operation = instance_double('Operation')

    expect(operation_class).to receive(:new).with(context: context, emitter: :emit).and_return(operation)

    expect(factory.operation(operation_class, emitter: :emit)).to eq(operation)
  end

  it 'memoizes the query inventory wrapper for the shared context' do
    first = factory.query_inventory
    second = factory.query_inventory

    expect(first).to be_a(Moose::Inventory::Operations::QueryInventory)
    expect(second).to equal(first)
  end
end
