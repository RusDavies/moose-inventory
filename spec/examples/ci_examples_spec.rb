# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'tmpdir'
require 'yaml'

RSpec.describe 'CI/CD examples' do
  it 'ships parseable inventory and GitHub Actions examples' do
    expect(YAML.safe_load_file('examples/ci/inventory/example-snapshot.yml')).to include('version' => 1)
    workflow = YAML.safe_load_file('examples/ci/github-actions/inventory-review.yml')

    expect(workflow).to include('name' => 'Inventory review example')
  end

  it 'keeps the snapshot validation script syntax-valid' do
    expect(system('bash', '-n', 'examples/ci/scripts/validate-inventory-snapshot.sh')).to eq(true)
  end

  it 'validates a snapshot and writes review artifacts without production credentials' do
    Dir.mktmpdir do |dir|
      command = 'bundle exec ruby -Ilib bin/moose-inventory'
      result = system(
        { 'MOOSE_INVENTORY_CMD' => command },
        'examples/ci/scripts/validate-inventory-snapshot.sh',
        'examples/ci/inventory/example-snapshot.yml',
        dir
      )

      expect(result).to eq(true)
      expect(File).to exist(File.join(dir, 'doctor.txt'))
      expect(YAML.safe_load_file(File.join(dir, 'inventory.yml'))).to include('hosts')
      expect(JSON.parse(File.read(File.join(dir, 'hosts.json')))).to include('web01')
      expect(JSON.parse(File.read(File.join(dir, 'ansible-inventory.json')))).to include('web')
    end
  end
end
