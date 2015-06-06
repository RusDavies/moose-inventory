require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "host list" method of the CLI
      class Host
        desc 'list', 'List the contents of the inventory by host'
        def list # rubocop:disable Metrics/AbcSize
          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Process
          results = {}
          db.models[:host].all.each do |host|
            groups = host.groups_dataset.map(:name)
            results[host[:name].to_sym] = {}
            results[host[:name].to_sym][:groups] = groups

            hostvars = {}
            host.hostvars_dataset.each do |hv| 
              hostvars[hv[:name].to_sym] = hv[:value] 
            end

            unless hostvars.length == 0
              results[host[:name].to_sym][:hostvars] = hostvars
            end
          end
          fmt.dump(results)
        end
      end
    end
  end
end
