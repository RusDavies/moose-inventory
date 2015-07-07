if RUBY_VERSION >= '1.9'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter # ,
    # Coveralls::SimpleCov::Formatter
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
require 'find'
require 'moose_inventory'

RSpec.configure do |config|
  #config.filter_run focus: true # <- enable to allow test focus
  config.color = true
  config.tty = true
  config.formatter = :progress #:documentation # :progress, :html, :textmate
  def capture(stream)
    case stream
    when :STDOUT
      begin
        orig = $stdout
        $stdout = StringIO.new
        yield
        result = $stdout.string
      ensure
        $stdout = orig
      end
    when :STDERR
      begin
        orig = $stderr
        $stderr = StringIO.new
        yield
        result = $stderr.string
      ensure
        $stderr = orig
      end
    end
    result
  end

  def runner
    out = { aborted: false, unexpected: false }

    out[:STDERR] = capture(:STDERR) do
      out[:STDOUT] = capture(:STDOUT) do
        begin
          yield

        rescue SystemExit
          out[:aborted] = true

        # rubocop:disable Lint/RescueException
        rescue Exception => e
          # rubocop:enable Lint/RescueException
          out[:unexpected] = e
        end
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

  def clobber_db_files
    paths = []
    Find.find('tmp/') { |path|  paths << path if path =~ /.*\.db$/ }
    paths.each { |file|  File.delete(file) }
  end

  def spec_root
    File.dirname(__FILE__)
  end

  # Always start with a fresh db file.
  clobber_db_files
end
