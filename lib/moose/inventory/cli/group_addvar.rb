require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group addvar" method of the CLI
      class Group
        #==========================
        desc 'addvar NAME VARNAME=VALUE',
             'Add a variable VARNAME with value VALUE to the group NAME'
        def addvar
          puts 'group addvar'
        end
      end
    end
  end
end
