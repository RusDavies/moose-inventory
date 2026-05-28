# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

# rubocop:disable Metrics/BlockLength
RSpec.describe Moose::Inventory::Cli::Console do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Application)
  end

  before(:each) do
    reset_cli_harness
  end

  def run_console(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    runner { @app.start(%w[console]) }
  ensure
    $stdin = original_stdin
  end

  it 'prints help and exits' do
    actual = run_console("help\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Moose Inventory console (read-only). Type help or quit.')
    expect(actual[:STDOUT]).to include('- hosts')
    expect(actual[:STDOUT]).to include('- group NAME')
    expect(actual[:STDOUT]).to include('Goodbye.')
  end

  it 'browses hosts, groups, tags, and entity detail without mutating' do
    runner { @app.start(%w[group add web]) }
    runner { @app.start(%w[host add web01 --groups web]) }
    runner { @app.start(%w[host addtag web01 prod]) }
    before_audit_count = @db.models[:audit_event].count

    actual = run_console("hosts\ngroups\nhost web01\ntags host web01\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Hosts: web01')
    expect(actual[:STDOUT]).to include('Groups: web')
    expect(actual[:STDOUT]).to include('Host: web01')
    expect(actual[:STDOUT]).to include('Tags: prod')
    expect(@db.models[:audit_event].count).to eq(before_audit_count)
  end

  it 'reports unknown and missing entities safely' do
    actual = run_console("nonsense\nhost missing\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Unknown command: nonsense')
    expect(actual[:STDOUT]).to include("Host 'missing' not found.")
  end
end
# rubocop:enable Metrics/BlockLength
