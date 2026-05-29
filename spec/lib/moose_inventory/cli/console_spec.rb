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

  it 'supports quoted read-only entity names' do
    group = @db.models[:group].create(name: 'prod group')
    host = @db.models[:host].create(name: 'web 01')
    tag = @db.models[:tag].create(name: 'critical host')
    host.add_group(group)
    host.add_tag(tag)
    before_audit_count = @db.models[:audit_event].count

    actual = run_console("host \"web 01\"\ntags host \"web 01\"\ngroup 'prod group'\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Host: web 01')
    expect(actual[:STDOUT]).to include('Groups: prod group')
    expect(actual[:STDOUT]).to include('critical host')
    expect(actual[:STDOUT]).to include('Group: prod group')
    expect(actual[:STDOUT]).to include('Hosts: web 01')
    expect(@db.models[:audit_event].count).to eq(before_audit_count)
  end

  it 'reports command-specific usage for extra or invalid arguments' do
    actual = run_console("host one two\ntags host\naudit nope\naudit 0\nhelp extra\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Usage: host NAME')
    expect(actual[:STDOUT]).to include('Usage: tags host|group NAME')
    expect(actual[:STDOUT].scan('Usage: audit [LIMIT]').length).to eq(2)
    expect(actual[:STDOUT]).to include('Usage: help')
  end

  it 'reports unclosed quoted input without leaving read-only mode' do
    before_audit_count = @db.models[:audit_event].count

    actual = run_console("host \"unterminated\nquit\n")

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:STDOUT]).to include('Invalid command syntax:')
    expect(actual[:STDOUT]).to include('Goodbye.')
    expect(@db.models[:audit_event].count).to eq(before_audit_count)
  end
end
# rubocop:enable Metrics/BlockLength
