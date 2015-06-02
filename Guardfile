# -*- mode: ruby -*-
# vi: set ft=ruby :

# More info at https://github.com/guard/guard#readme

clearing :on
#
group :bundler do
  watch('Gemfile')
  watch(%r{.*\.gemspec})
end

group 'unit-tests' do
  guard :rspec, cmd: "bundle exec rspec -I lib/moose/inventory -I spec" do
    require "guard/rspec/dsl"
    dsl = Guard::RSpec::Dsl.new(self)
  
    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_helper) { rspec.spec_dir }
    watch(rspec.spec_support) { rspec.spec_dir }
    watch(rspec.spec_files)
  
    # Ruby files
    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)
  
  end
end