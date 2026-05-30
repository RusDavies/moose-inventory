# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'tmpdir'

RSpec.describe Moose::Inventory::Cli::Application do
  before(:all) do
    setup_cli_harness(command_class: described_class)
  end

  before(:each) do
    reset_cli_harness
  end

  it 'exports the current inventory snapshot as yaml' do
    runner { @app.start(%w[host add web01]) }
    runner { @app.start(%w[group add web]) }
    runner { @app.start(%w[host addgroup web01 web]) }

    actual = runner { @app.start(%w[export]) }

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:aborted]).to eq(false)
    expect(actual[:STDERR]).to eq('')
    snapshot = YAML.safe_load(actual[:STDOUT])
    expect(snapshot['version']).to eq(1)
    expect(snapshot.dig('hosts', 'web01', 'groups')).to include('web')
    expect(snapshot['groups']).to have_key('web')
  end

  it 'imports a validated inventory snapshot file' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'inventory.yml')
      File.write(
        path,
        {
          'version' => 1,
          'hosts' => { 'web01' => { 'groups' => ['web'], 'tags' => [], 'vars' => { 'env' => 'prod' } } },
          'groups' => { 'web' => { 'children' => [], 'tags' => [], 'vars' => { 'role' => 'frontend' } } }
        }.to_yaml
      )

      actual = runner { @app.start(['import', path]) }

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDERR]).to eq('')
      expect(actual[:STDOUT]).to include("Imported inventory snapshot from #{path}.")
      host = @db.models[:host].find(name: 'web01')
      expect(host.groups_dataset[name: 'web']).not_to be_nil
      expect(host.hostvars_dataset[name: 'env'][:value]).to eq('prod')
    end
  end

  it 'previews an inventory snapshot import without writing' do
    runner { @app.start(%w[group add web]) }

    Dir.mktmpdir do |dir|
      path = File.join(dir, 'inventory.yml')
      File.write(
        path,
        {
          'version' => 1,
          'hosts' => { 'web01' => { 'groups' => ['web'], 'tags' => [], 'vars' => { 'env' => 'prod' } } },
          'groups' => { 'web' => { 'children' => [], 'tags' => [], 'vars' => {} } }
        }.to_yaml
      )

      actual = runner { @app.start(['import', path, '--preview', '--preview-format', 'json']) }

      expect(actual[:unexpected]).to eq(false)
      expect(actual[:aborted]).to eq(false)
      expect(actual[:STDERR]).to eq('')
      preview = JSON.parse(actual[:STDOUT])
      expect(preview['schema_version']).to eq('snapshot-import-preview-v1')
      expect(preview['changes_applied']).to eq(false)
      expect(preview.dig('summary', 'hosts_created')).to eq(1)
      expect(preview.dig('creates', 'hosts')).to eq(['web01'])
      expect(@db.models[:host].find(name: 'web01')).to be_nil
    end
  end

  it 'aborts on invalid snapshot input without writing' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'inventory.yml')
      File.write(
        path,
        { 'version' => 1, 'hosts' => { 'web01' => { 'groups' => ['missing'], 'vars' => {} } }, 'groups' => {} }.to_yaml
      )

      actual = runner { @app.start(['import', path]) }

      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to include("Invalid inventory snapshot: host 'web01' references unknown group 'missing'.")
      expect(@db.models[:host].count).to eq(0)
    end
  end

  it 'sanitizes alias rejection errors while previewing snapshot import' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'inventory.yml')
      File.write(path, "---\nversion: 1\ngroups: &groups {}\nhosts: *groups\n")

      actual = runner { @app.start(['import', path, '--preview']) }

      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to include("ERROR: Could not load inventory snapshot '#{path}':")
      expect(actual[:STDERR]).to include('Alias parsing was not enabled')
      expect(actual[:STDERR]).not_to include('/psych/')
      expect(actual[:STDERR]).not_to include('from ')
      expect(@db.models[:host].count).to eq(0)
    end
  end

  it 'sanitizes disallowed class errors while previewing snapshot import' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'inventory.yml')
      File.write(path, "---\nversion: 1\ngroups:\n  g: {}\n  :g: {}\nhosts: {}\n")

      actual = runner { @app.start(['import', path, '--preview']) }

      expect(actual[:aborted]).to eq(true)
      expect(actual[:STDERR]).to include("ERROR: Could not load inventory snapshot '#{path}':")
      expect(actual[:STDERR]).to include('Tried to load unspecified class: Symbol')
      expect(actual[:STDERR]).not_to include('/psych/')
      expect(actual[:STDERR]).not_to include('from ')
      expect(@db.models[:host].count).to eq(0)
    end
  end
end
# rubocop:enable Metrics/BlockLength
