require 'thor'
require_relative './config/config.rb'
require_relative './db/db.rb'
require_relative './cli/application.rb'

module Moose
  module Inventory
     module Cli
       extend self

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
