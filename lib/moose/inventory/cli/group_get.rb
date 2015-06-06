require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group get" method of the CLI
      class Group
        desc 'get NAME', 'Get a group NAME from the inventory'
        def get(name) # rubocop:disable Metrics/AbcSize
          # Convenience
          db    = Moose::Inventory::DB

          # Arguments
          name = name.downcase
          group = db.models[:group].find(name: name)

          # Process
          results = {}
          if !group.nil?
            hosts = group.hosts_dataset.map(:name)
            groupvars = {}
            group.groupvars_dataset.each do |gv|
              groupvars[gv[:name].to_sym] = gv[:value]
            end

            results[group[:name].to_sym] = {}
            unless hosts.length == 0
              results[group[:name].to_sym][:hosts]     = hosts
            end
            unless groupvars.length == 0
              results[group[:name].to_sym][:groupvars] = groupvars
            end

            Formatter.out(results)
          else
            Formatter.out(results)
            abort('No results')
          end
        end
      end
    end
  end
end
