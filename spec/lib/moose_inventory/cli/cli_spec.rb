# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moose::Inventory::Cli do
  describe '.start' do
    it 'wires config, db, and application explicitly' do
      args = ['--format', 'yaml']
      config = instance_double('Config')
      db = instance_double('DB')
      application = class_double('Application')

      expect(config).to receive(:init).with(args).ordered
      expect(db).to receive(:init).ordered
      expect(config).to receive(:application_args).ordered.and_return(['version'])
      expect(application).to receive(:start).with(['version']).ordered

      described_class.start(args, config: config, db: db, application: application)
    end
  end
end
