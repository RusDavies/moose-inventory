# -*- mode: ruby -*-
# vi: set ft=ruby :

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moose_inventory/version'

Gem::Specification.new do |spec|
  spec.name          = 'moose-inventory'
  spec.version       = Moose::Inventory::VERSION
  spec.authors       = ['Russell Davies']
  spec.email         = ['russell@blakemere.ca']
  spec.summary       = 'Moose-tools inventory manager'
  # rubocop:disable Metrics/LineLength
  spec.description   = 'The Moosecastle CLI tool for Ansible-compatable dynamic inventory management.'
  # rubocop:enable Metrics/LineLength
  spec.homepage      = 'https://github.com/RusDavies/moose-inventory'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'indentation', '~> 0.1'
  spec.add_runtime_dependency 'json',        '~>1.8'
  spec.add_runtime_dependency 'mysql',       '~>2.9'
  # spec.add_runtime_dependency 'mysql2',    '~>0.3'
  spec.add_runtime_dependency 'pg',        '~>0.17'
  spec.add_runtime_dependency 'sequel',    '~>4.22'
  spec.add_runtime_dependency 'sqlite3',   '~>1.3'
  spec.add_runtime_dependency 'thor',      '~>0.19'
  # spec.add_runtime_dependency   'yaml',      '~>1.0'

  spec.add_development_dependency 'bundler',      '~> 1.7'
  spec.add_development_dependency 'coveralls',    '~> 0.8'
  spec.add_development_dependency 'hitimes',      '~> 1.2'
  spec.add_development_dependency 'guard',        '~> 2.12'
  spec.add_development_dependency 'guard-rspec',  '~> 4.5'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'rake',         '~> 10.1'
  spec.add_development_dependency 'rspec',        '~>3.2'
  spec.add_development_dependency 'rubocop',      '>= 0.19'
  spec.add_development_dependency 'simplecov',    '~> 0.10'
end
