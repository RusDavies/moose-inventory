require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "group" methods of the CLI
      class Group < Thor
        require_relative 'group_add'
        require_relative 'group_get'
        require_relative 'group_list'
        require_relative 'group_rm'
        require_relative 'group_addchild'
        require_relative 'group_rmchild'
        require_relative 'group_addhost'
        require_relative 'group_rmhost'
        require_relative 'group_addvar'
        require_relative 'group_listvars'
        require_relative 'group_rmvar'
      end
    end
  end
end
