#!/usr/bin/env ruby

require 'yaml'

files = `git ls-files -z`.split("\x0")
executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
test_files    = files.grep(%r{^(test|spec|features)/})
require_paths = ['lib']

out = {}
out['Executables'.to_sym] = executables
out['Test_Files'.to_sym] = test_files
out['Require_Paths'.to_sym] = require_paths

puts "#{out.to_yaml}"



