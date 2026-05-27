# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moose::Inventory::Cli::Application do
  describe 'version' do
    it 'prints the current Moose Inventory version' do
      output = capture(:STDOUT) do
        described_class.start(%w[version])
      end

      expect(output).to eq("Version #{Moose::Inventory::VERSION}\n")
    end
  end

  describe 'subcommands' do
    it 'registers the group subcommand' do
      expect(described_class.subcommands).to include('group')
    end

    it 'registers the host subcommand' do
      expect(described_class.subcommands).to include('host')
    end
  end
end
