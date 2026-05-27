# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moose::Inventory::DB::MooseDBException do
  it 'uses the provided exception message through RuntimeError' do
    error = described_class.new('boom')

    expect(error.message).to eq('boom')
    expect(error.full_message).to include('boom')
  end

  it 'falls back to a default exception message' do
    error = described_class.new

    expect(error.message).to eq('An undefined Moose exception occurred')
  end
end
