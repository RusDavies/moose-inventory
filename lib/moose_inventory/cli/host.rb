require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "host" methods of the CLI
      class Host < Thor
        require_relative 'host_add'
        require_relative 'host_get'
        require_relative 'host_list'
        require_relative 'host_rm'
        require_relative 'host_addgroup'
        require_relative 'host_rmgroup'
        require_relative 'host_addvar'
        require_relative 'host_listvars'
        require_relative 'host_rmvar'
      end
    end
  end
end
