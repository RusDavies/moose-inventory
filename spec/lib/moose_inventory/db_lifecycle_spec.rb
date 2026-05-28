# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'tmpdir'

RSpec.describe 'database lifecycle commands' do
  before(:all) do
    setup_cli_harness(command_class: Moose::Inventory::Cli::Application)
  end

  before(:each) do
    reset_cli_harness
  end

  it 'records the current schema version during database initialization' do
    expect(Moose::Inventory::DB.schema_version).to eq(Moose::Inventory::DB::SCHEMA_VERSION)
    expect(Moose::Inventory::DB.status[:tables][:schema_info]).to eq(true)
  end

  it 'prints database status' do
    actual = runner { @app.start(%w[db status]) }

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:aborted]).to eq(false)
    expect(actual[:STDOUT]).to include('Adapter: sqlite3')
    expect(actual[:STDOUT]).to include("Expected schema version: #{Moose::Inventory::DB::SCHEMA_VERSION}")
    expect(actual[:STDOUT]).to include('- schema_info: present')
  end

  it 'runs db doctor successfully when schema state is current' do
    actual = runner { @app.start(%w[db doctor]) }

    expected(actual, aborted: false, STDOUT: "Database doctor found no issues.\n", STDERR: '')
  end

  it 'reports dirty partial schema state through db doctor' do
    Moose::Inventory::DB.db.drop_table(:audit_events)

    actual = runner { @app.start(%w[db doctor]) }

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:aborted]).to eq(true)
    expect(actual[:STDOUT]).to include('Database doctor found issue(s):')
    expect(actual[:STDOUT]).to include('- Missing tables: audit_events')
  end

  it 'migrates missing lifecycle metadata' do
    Moose::Inventory::DB.db.drop_table(:schema_info)

    actual = runner { @app.start(%w[db migrate]) }

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:aborted]).to eq(false)
    expect(actual[:STDOUT]).to include("Database schema is at version #{Moose::Inventory::DB::SCHEMA_VERSION}.")
    expect(Moose::Inventory::DB.schema_version).to eq(Moose::Inventory::DB::SCHEMA_VERSION)
  end

  it 'backs up the sqlite database file' do
    Dir.mktmpdir do |dir|
      destination = File.join(dir, 'backup.sqlite3')

      actual = runner { @app.start(['db', 'backup', destination]) }

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDOUT]).to include("Backed up database to #{destination}.")
      expect(File).to exist(destination)
      expect(File.size(destination)).to be_positive
    end
  end
end
# rubocop:enable Metrics/BlockLength
