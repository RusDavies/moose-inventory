# frozen_string_literal: true

require 'spec_helper'
require 'inventory_context'

RSpec.describe Moose::Inventory::InventoryContext do
  it 'requires an explicit db dependency' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end
end
