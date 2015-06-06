require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group addchild" methods of the CLI
      class Group < Thor # rubocop:disable ClassLength
        #==========================
        desc 'addchild [options] NAME CHILDNAME',
             'Associate a child-group CHILDNAME with the group NAME'
        option :allowcreate, type: :boolean
        def addchild
          abort("The 'groups addchild GROUP' method is not yet implemented")
          puts 'group addchild'
        end
      end
    end
  end
end
