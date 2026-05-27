#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

files = `git ls-files -z`.split("\x0")
executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
test_files    = files.grep(%r{^(test|spec|features)/})
require_paths = ['lib']

out = {}
out[:Executables] = executables
out[:Test_Files] = test_files
out[:Require_Paths] = require_paths

puts out.to_yaml
