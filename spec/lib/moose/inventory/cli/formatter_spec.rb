require 'spec_helper'

# TODO: the usual respond_to? method doesn't seem to work on Thor objects.
# Why not? For now, we'll check against instance_methods.

RSpec.describe Moose::Inventory::Cli::Formatter do
  before(:all) do
    @formatter = Moose::Inventory::Cli::Formatter
  end

  # ============================
  describe 'out' do
    # --------------------
    it 'Formatter.out() method should be responsive' do
      expect(@formatter.respond_to?(:out)).to eq(true)
    end

    # --------------------
    it 'out(<object>, \'yaml\') ... should output as yaml' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'yaml') }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = test.to_yaml

      expected(actual, desired)
    end

    it 'out(<object>, \'json\') ... should output as ugly json' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'json') }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = test.to_json + "\n"

      expected(actual, desired)
    end

    it 'out(<object>, \'prettyjson\') ... should output as pretty json' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'prettyjson') }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = JSON.pretty_generate(test) + "\n"

      expected(actual, desired)
    end

    it 'out(<object>, \'unknown-type\') ... should abort with an error' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'unknown-type') }

      desired = { aborted: true, STDOUT: '', STDERR: '' }
      desired[:STDERR] = "Output format 'unknown-type' is not yet supported.\n"

      expected(actual, desired)
    end
  end
end
