require 'thor'
require_relative './moose_inventory/config/config.rb'
require_relative './moose_inventory/db/db.rb'
require_relative './moose_inventory/cli/application.rb'

module Moose
  module Inventory
    ##
    # Module implementing the CLI for moose-inventory
    module Cli
      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      def start(args)
        # initialization stuff.
        Moose::Inventory::Config.init(args)
        Moose::Inventory::DB.init

        # Start the main application
        Moose::Inventory::Cli::Application.start(Moose::Inventory::Config._argv)
      end
    end
  end
end
