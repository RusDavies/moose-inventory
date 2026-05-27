# frozen_string_literal: true

require 'thor'
require_relative '../version'
require_relative '../config/config'
require_relative 'group'
require_relative 'host'

module Moose
  module Inventory
    module Cli
      ##
      # Top-level Thor application for moose-inventory.
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
