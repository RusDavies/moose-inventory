require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group rmchild" methods of the CLI
      class Group < Thor # rubocop:disable ClassLength
        #==========================
        desc 'rmchild NAME CHILDNAME',
             'Dissociate a child-group CHILDNAME from the group NAME'
        def rmchild
          abort("The 'groups rmchild GROUP' method is not yet implemented")
          puts 'group rmchild'
        end
      end
    end
  end
end
