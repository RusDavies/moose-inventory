# -*- mode: ruby -*-
# vi: set ft=ruby :

# More info at https://github.com/guard/guard#readme

clearing :on
#
group :bundler do
  watch('Gemfile')
  watch(/.*\.gemspec/)
end

group 'quality' do
  opts = ' -D -a --format html -o spec/reports/quality/rubocop.html'.split(' ')
  guard :rubocop, all_on_start: true,  cli: opts do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end

group 'test' do 
  cmd = 'bundle exec rspec -I lib/moose/inventory -I spec '\
    '--color --format html --out spec/reports/test/rspec.html'
  guard :rspec, cmd: cmd do
    require 'guard/rspec/dsl'
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
