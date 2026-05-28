# frozen_string_literal: true

require 'json'
require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Moose::Inventory::Cli::Audit do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Audit)
  end

  before(:each) do
    reset_cli_harness
  end

  it 'starts with an empty audit log' do
    actual = runner { @app.start(%w[audit list]) }

    expected(actual, aborted: false, STDOUT: "No audit events recorded.\n", STDERR: '')
  end

  it 'records successful mutating host commands' do
    add = runner { @app.start(%w[host add app01]) }
    expect(add[:unexpected]).to eq(false)

    event = @db.models[:audit_event].last
    expect(event.command).to eq('host add')
    expect(event.action).to eq('add')
    expect(event.entity_type).to eq('host')
    expect(event.entity_name).to eq('app01')
    expect(JSON.parse(event.details)).to include('events')
  end

  it 'does not record dry-run commands' do
    actual = runner { @app.start(%w[host add --dry-run app01]) }
    expect(actual[:unexpected]).to eq(false)

    expect(@db.models[:audit_event].count).to eq(0)
  end

  it 'lists audit events as machine-readable JSON' do
    runner { @app.start(%w[group add web]) }

    actual = runner { @app.start(%w[audit list --format json]) }
    parsed = JSON.parse(actual[:STDOUT])

    expect(actual[:unexpected]).to eq(false)
    expect(parsed.first).to include(
      'command' => 'group add',
      'action' => 'add',
      'entity_type' => 'group',
      'entity_name' => 'web'
    )
  end
end
# rubocop:enable Metrics/BlockLength
