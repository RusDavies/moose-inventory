# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moose_inventory/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'moose-inventory'
  spec.version       = Moose::Inventory::VERSION
  spec.authors       = ['Russell Davies']
  spec.email         = ['russell@blakemere.ca']
  spec.summary       = 'Moose-tools inventory manager'
  spec.description   = 'The Moosecastle CLI tool for Ansible-compatible dynamic inventory management.'
  spec.homepage      = 'https://github.com/RusDavies/moose-inventory'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'indentation', '~> 0'
  spec.add_dependency 'json', '>= 2.7', '< 3'
  spec.add_dependency 'mysql2', '>= 0.5.7', '< 0.6'
  spec.add_dependency 'pg', '>= 1.5', '< 2'
  spec.add_dependency 'sequel', '>= 5.80', '< 6'
  spec.add_dependency 'sqlite3', '>= 1.7', '< 3'
  spec.add_dependency 'thor', '>= 1.3', '< 2'

  # rubocop:disable Gemspec/DevelopmentDependencies
  # Development dependencies intentionally remain here because this project uses
  # `gemspec` as its Gemfile dependency source.
  spec.add_development_dependency 'bundler', '>= 2.2.33', '< 3'
  spec.add_development_dependency 'bundler-audit', '>= 0.9', '< 1'
  spec.add_development_dependency 'parallel', '>= 1.10', '< 2.0'
  spec.add_development_dependency 'rake', '>= 13.0', '< 14'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop', '>= 1.72', '< 2'
  spec.add_development_dependency 'simplecov', '~> 0'
  # rubocop:enable Gemspec/DevelopmentDependencies
end
# rubocop:enable Metrics/BlockLength
