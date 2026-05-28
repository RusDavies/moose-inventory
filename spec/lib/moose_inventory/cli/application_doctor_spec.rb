# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

RSpec.describe Moose::Inventory::Cli::Application do
  before(:all) do
    setup_cli_harness(command_class: described_class)
  end

  before(:each) do
    reset_cli_harness
  end

  it 'prints a human success report when no issues are found' do
    web = @db.models[:group].create(name: 'web')
    host = @db.models[:host].create(name: 'web01')
    host.add_group(web)

    actual = runner { @app.start(%w[doctor]) }

    expected(actual, aborted: false, STDOUT: "Inventory doctor found no issues.\n", STDERR: '')
  end

  it 'prints a human report and exits nonzero when issues are found' do
    @db.models[:group].create(name: 'ungrouped')
    host = @db.models[:host].create(name: 'lonely')
    host.add_group(@db.models[:group].find(name: 'ungrouped'))

    actual = runner { @app.start(%w[doctor]) }

    expect(actual[:aborted]).to eq(true)
    expect(actual[:STDOUT]).to include('Inventory doctor found')
    expect(actual[:STDOUT]).to include('host_only_in_ungrouped')
  end

  it 'prints a machine-readable report when requested' do
    @db.models[:group].create(name: 'ungrouped')
    host = @db.models[:host].create(name: 'lonely')
    host.add_group(@db.models[:group].find(name: 'ungrouped'))

    actual = runner { @app.start(%w[doctor --format json]) }

    expect(actual[:aborted]).to eq(true)
    report = JSON.parse(actual[:STDOUT])
    expect(report['ok']).to eq(false)
    expect(report['issues'].map { |issue| issue['id'] }).to include('host_only_in_ungrouped')
  end
end
# rubocop:enable Metrics/BlockLength
