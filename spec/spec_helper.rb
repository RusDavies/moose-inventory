
$TESTING = true

if RUBY_VERSION >= '1.9'
  require "simplecov"
  require "coveralls"

  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

  SimpleCov.start do
    add_filter "/spec"
    minimum_coverage(91.69)
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib/moose/inventory"))


#require 'rdoc'
require 'rspec'
require 'json'
require 'yaml'
require  'moose-inventory-cli'

  
RSpec.configure do |config|
  config.color = true
  config.tty = true
  #config.formatter = :documentation # :progress, :html, :textmate
  
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def spec_root
    File.direname(__FILE__)
  end
  
  # This code was adapted from Ruby on Rails, available under MIT-LICENSE
  # Copyright (c) 2004-2013 David Heinemeier Hansson
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  alias silence capture
end


# See https://github.com/cldwalker/hirb/blob/master/test/test_helper.rb
#module TestHelpers
#  def self.specdir
#    File.dirname(__FILE__)
#  end
#end
