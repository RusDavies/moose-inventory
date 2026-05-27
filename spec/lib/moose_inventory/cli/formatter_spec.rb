# frozen_string_literal: true

require 'spec_helper'

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
      desired[:STDOUT] = "#{test.to_json}\n"

      expected(actual, desired)
    end

    it 'out(<object>, \'prettyjson\') ... should output as pretty json' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'prettyjson') }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = "#{JSON.pretty_generate(test)}\n"

      expected(actual, desired)
    end

    it 'out(<object>, \'unknown-type\') ... should abort with an error' do
      test = { name: 'turkey', data: [1, 2, 3] }

      actual = runner { @formatter.out(test, 'unknown-type') }

      desired = { aborted: true, STDOUT: '', STDERR: '' }
      desired[:STDERR] = "Output format 'unknown-type' is not yet supported.\n"

      expected(actual, desired)
    end

    it 'info() prints the provided message instead of a literal placeholder' do
      actual = runner { @formatter.info(2, 'hello world') }

      desired = { aborted: false, STDOUT: '', STDERR: '' }
      desired[:STDOUT] = '  INFO: hello world'

      expected(actual, desired)
    end
  end

  describe 'stream helpers' do
    it 'puts() writes indented text to stdout by default' do
      actual = runner { @formatter.puts(2, 'hello world') }

      desired = { aborted: false, STDOUT: "  hello world\n", STDERR: '' }

      expected(actual, desired)
    end

    it 'puts() writes indented text to stderr when requested' do
      actual = runner { @formatter.puts(2, 'hello world', 'STDERR') }

      desired = { aborted: false, STDOUT: '', STDERR: "  hello world\n" }

      expected(actual, desired)
    end

    it 'puts() aborts on an unknown output stream' do
      actual = runner { @formatter.puts(2, 'hello world', 'BOGUS') }

      desired = { aborted: true, STDOUT: '', STDERR: "Output stream 'BOGUS' is not known.\n" }

      expected(actual, desired)
    end

    it 'print() writes indented text to stdout by default' do
      actual = runner { @formatter.print(2, 'hello world') }

      desired = { aborted: false, STDOUT: '  hello world', STDERR: '' }

      expected(actual, desired)
    end

    it 'print() writes indented text to stderr when requested' do
      actual = runner { @formatter.print(2, 'hello world', 'STDERR') }

      desired = { aborted: false, STDOUT: '', STDERR: '  hello world' }

      expected(actual, desired)
    end

    it 'print() aborts on an unknown output stream' do
      actual = runner { @formatter.print(2, 'hello world', 'BOGUS') }

      desired = { aborted: true, STDOUT: '', STDERR: "Output stream 'BOGUS' is not known.\n" }

      expected(actual, desired)
    end

    it 'info() writes to stderr when requested' do
      actual = runner { @formatter.info(2, 'hello world', 'STDERR') }

      desired = { aborted: false, STDOUT: '', STDERR: '  INFO: hello world' }

      expected(actual, desired)
    end

    it 'info() aborts on an unknown output stream' do
      actual = runner { @formatter.info(2, 'hello world', 'BOGUS') }

      desired = { aborted: true, STDOUT: '', STDERR: "Output stream 'BOGUS' is not known.\n" }

      expected(actual, desired)
    end

    it 'warn() writes to stderr with the warning prefix' do
      actual = runner { @formatter.warn('hello world') }

      desired = { aborted: false, STDOUT: '', STDERR: 'WARNING: hello world' }

      expected(actual, desired)
    end

    it 'error() writes to stderr with the error prefix' do
      actual = runner { @formatter.error('hello world') }

      desired = { aborted: false, STDOUT: '', STDERR: 'ERROR: hello world' }

      expected(actual, desired)
    end
  end
end
