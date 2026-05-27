# frozen_string_literal: true

if RUBY_VERSION >= '1.9'
  require 'simplecov'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter
  ]

  SimpleCov.start do
    coverage_dir 'spec/reports/coverage'
    # coverage_path 'spec/reports/coverage'
    add_group 'bin', 'bin'
    add_group 'lib', 'lib'

    add_filter '/config'
    add_filter '/coverage'
    add_filter '/spec'
    add_filter '/test'
    add_filter '/tmp'

    minimum_coverage(90)
    # minimum_coverage_by_file(80)
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),
                             '..', 'lib/moose_inventory'))

# require 'rdoc'
require 'rspec'
require 'json'
require 'yaml'
require 'fileutils'
require 'find'
require 'moose_inventory'
require_relative 'support/cli_harness'

module SpecOutputHelpers
  def capture(stream, &)
    case stream
    when :STDOUT
      capture_stdout(&)
    when :STDERR
      capture_stderr(&)
    end
  end

  def capture_stdout
    orig = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = orig
  end

  def capture_stderr
    orig = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = orig
  end

  def runner
    out = { aborted: false, unexpected: false }

    out[:STDERR] = capture(:STDERR) do
      out[:STDOUT] = capture(:STDOUT) do
        yield
      rescue SystemExit
        out[:aborted] = true
      # rubocop:disable Lint/RescueException
      rescue Exception => e
        # rubocop:enable Lint/RescueException
        out[:unexpected] = e
      end
    end
    out # return the output
  end

  def expected(actual, desired)
    desired[:aborted].nil? && desired[:aborted] = false
    desired[:STDOUT].nil? && desired[:STDOUT] = ''
    desired[:STDERR].nil? && desired[:STDERR] = ''

    expect(actual[:unexpected]).to eq(false)
    expect(actual[:aborted]).to eq(desired[:aborted])
    expect(actual[:STDOUT]).to eq(desired[:STDOUT])
    expect(actual[:STDERR]).to eq(desired[:STDERR])
  end

  def spec_root
    File.dirname(__FILE__)
  end
end

module SpecDatabaseHelpers
  def self.clobber_db_files
    FileUtils.mkdir_p('tmp')
    paths = []
    Find.find('tmp') { |path| paths << path if path =~ /.*\.db$/ }
    paths.each { |file| File.delete(file) }
  end
end

RSpec.configure do |config|
  config.include CliHarness
  config.include SpecOutputHelpers
  # config.filter_run focus: true # <- enable to allow test focus
  config.color = true
  config.tty = true
  config.formatter = :progress # :documentation # :progress, :html, :textmate

  config.before(:suite) do
    SpecDatabaseHelpers.clobber_db_files
  end
end
