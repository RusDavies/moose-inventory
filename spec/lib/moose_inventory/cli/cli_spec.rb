require 'spec_helper'

RSpec.describe Moose::Inventory::Cli::Application do
  before do
    @app = Moose::Inventory::Cli::Application
  end

  describe '.version' do
    # --------------------
    it 'method should be responsive' do
      result = @app.instance_methods(false).include?(:version)
      expect(result).to eq(true)
    end

    # --------------------
    #    it 'should output version information' do
    #      actual = runner { @app.version }
    #
    #      desired = {}
    #      desired[:STDERR] = "Version #{Moose::Inventory::VERSION}"
    #
    #      expected(actual, desired)
    #    end
  end
end
