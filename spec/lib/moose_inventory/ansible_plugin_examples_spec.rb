# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'Ansible inventory plugin examples' do
  it 'ships a plugin, inventory source, and ansible.cfg example' do
    expect(File).to exist('examples/ansible/inventory_plugins/moose_inventory.py')
    expect(File).to exist('examples/ansible/inventory/moose_inventory.yml')
    expect(File).to exist('examples/ansible/ansible.cfg')
  end

  it 'uses the moose_inventory plugin in the example inventory source' do
    config = YAML.safe_load_file('examples/ansible/inventory/moose_inventory.yml')

    expect(config).to include(
      'plugin' => 'moose_inventory',
      'executable' => 'moose-inventory',
      'config' => './example.conf',
      'env' => 'dev'
    )
  end

  it 'keeps the plugin source syntax-valid' do
    result = system('python3', '-m', 'py_compile', 'examples/ansible/inventory_plugins/moose_inventory.py')

    expect(result).to eq(true)
  end
end
