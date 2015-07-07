require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group list" method of the CLI
      class Group
        #==========================
        desc 'list',
             'List the groups, together with any associated hosts and groupvars'
        option :ansiblestyle, type: :boolean
        def list # rubocop:disable Metrics/AbcSize
          # Convenience
          db    = Moose::Inventory::DB

          # Process
          results = {}
          db.models[:group].all.each do |group|
            hosts = group.hosts_dataset.map(:name)

            groupvars = {}
            group.groupvars_dataset.each do |gv|
              groupvars[gv[:name].to_sym] = gv[:value]
            end

            results[group[:name].to_sym] = {}
            unless hosts.length == 0
              results[group[:name].to_sym][:hosts] = hosts
            end
            unless groupvars.length == 0
              results[group[:name].to_sym][:groupvars] = groupvars
            end
          end
          Formatter.out(results)
        end
      end
    end
  end
end
