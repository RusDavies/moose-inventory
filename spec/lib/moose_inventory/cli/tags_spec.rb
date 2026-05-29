# frozen_string_literal: true

require 'json'
require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'host and group metadata tags' do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Application)
  end

  before(:each) do
    reset_cli_harness
  end

  it 'adds and lists host tags' do
    runner { @app.start(%w[host add app01]) }

    add = runner { @app.start(%w[host addtag app01 prod critical]) }
    list = runner { @app.start(%w[host listtags app01]) }

    expect(add[:unexpected]).to eq(false)
    expect(add[:STDOUT]).to include("Added host tag(s) to 'app01': prod, critical.")
    expect(list[:STDOUT]).to eq("Host 'app01' tags: critical, prod\n")
  end

  it 'normalizes host tag casing and deduplicates values' do
    runner { @app.start(%w[host add app01]) }

    add = runner { @app.start(%w[host addtag app01 Prod PROD owner-platform]) }
    list = runner { @app.start(%w[host listtags app01]) }

    expect(add[:unexpected]).to eq(false)
    expect(add[:STDOUT]).to include("Added host tag(s) to 'app01': prod, owner-platform.")
    expect(list[:STDOUT]).to eq("Host 'app01' tags: owner-platform, prod\n")
    expect(@db.models[:tag].where(name: 'Prod').count).to eq(0)
    expect(@db.models[:tag].where(name: 'prod').count).to eq(1)
  end

  it 'removes host tags' do
    runner { @app.start(%w[host add app01]) }
    runner { @app.start(%w[host addtag app01 prod critical]) }

    remove = runner { @app.start(%w[host rmtag app01 PROD]) }
    list = runner { @app.start(%w[host listtags app01]) }

    expect(remove[:unexpected]).to eq(false)
    expect(remove[:STDOUT]).to include("Removed host tag(s) from 'app01': prod.")
    expect(list[:STDOUT]).to eq("Host 'app01' tags: critical\n")
  end

  it 'adds and lists group tags as JSON' do
    runner { @app.start(%w[group add web]) }
    runner { @app.start(%w[group addtag web frontend owner-platform]) }

    actual = runner { @app.start(%w[group listtags web --format json]) }
    parsed = JSON.parse(actual[:STDOUT])

    expect(actual[:unexpected]).to eq(false)
    expect(parsed).to eq('group' => 'web', 'tags' => %w[frontend owner-platform])
  end

  it 'records audit events for tag changes' do
    runner { @app.start(%w[host add app01]) }
    runner { @app.start(%w[host addtag app01 prod]) }

    event = @db.models[:audit_event].last
    expect(event.command).to eq('host addtag')
    expect(event.action).to eq('add_tag')
    expect(event.entity_type).to eq('host')
    expect(event.entity_name).to eq('app01')
  end

  it 'aborts when tagging a missing entity' do
    actual = runner { @app.start(%w[group addtag missing prod]) }

    expect(actual[:aborted]).to eq(true)
    expect(actual[:STDERR]).to include("ERROR: The group 'missing' does not exist.")
  end
end
# rubocop:enable Metrics/BlockLength
