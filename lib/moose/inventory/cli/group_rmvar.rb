require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group rmvar" method of the CLI
      class Group
        #==========================
        desc 'rmvar NAME VARNAME',
             'Remove a variable VARNAME from the group NAME'
        def rmvar
          puts 'group rmvar'
        end
      end
    end
  end
end
