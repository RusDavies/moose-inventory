require 'thor'
require_relative '../version.rb'
require_relative '../config/config.rb'
require_relative './group.rb'
require_relative './host.rb'

module Moose
  module Inventory
    module Cli
      ##
      # TODO: Documentation
      class Application < Thor
        desc 'version', 'Get the code version'
        def version
          puts "Version #{Moose::Inventory::VERSION}"
        end

        desc 'group ACTION',
             'Manipulate groups in the inventory. ' \
             'ACTION can be add, rm, get, list, addhost, rmhost, addchild, rmchild, addvar, rmvar'
        subcommand 'group', Moose::Inventory::Cli::Group

        desc 'host ACTION',
             'Manipulate hosts in the inventory. ' \
             'ACTION can be add, rm, get, list, addgroup, rmgroup, addvar, rmvar'
        subcommand 'host', Moose::Inventory::Cli::Host
      end
    end
  end
end
