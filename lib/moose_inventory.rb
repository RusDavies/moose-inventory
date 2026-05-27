# frozen_string_literal: true

require 'thor'
require_relative 'moose_inventory/config/config'
require_relative 'moose_inventory/db/db'
require_relative 'moose_inventory/cli/application'

module Moose
  module Inventory
    ##
    # Module implementing the CLI for moose-inventory
    module Cli
      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      def start(args, config: Moose::Inventory::Config, db: Moose::Inventory::DB,
                application: Moose::Inventory::Cli::Application)
        # initialization stuff.
        config.init(args)
        db.init

        # Start the main application
        application.start(config.application_args)
      end
    end
  end
end
