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
        def list # rubocop:disable Metrics/AbcSize
          # Convenience
          db = Moose::Inventory::DB
          confopts = Moose::Inventory::Config._confopts

          # Process
          results = {}
          db.models[:group].all.each do |group|
            hosts = group.hosts_dataset.map(:name)

            # Hide the automatic ungrouped group, if it's empty
            next if group[:name] == 'ungrouped' && hosts.empty?

            children = group.children_dataset.map(:name)

            groupvars = {}
            group.groupvars_dataset.each do |gv|
              groupvars[gv[:name].to_sym] = gv[:value]
            end

            results[group[:name].to_sym] = {}
            unless hosts.empty? && (confopts[:ansible] != true)
              results[group[:name].to_sym][:hosts] = hosts
            end

            unless children.empty?
              results[group[:name].to_sym][:children] = children
            end

            next if groupvars.empty?
            if confopts[:ansible] == true
              results[group[:name].to_sym][:vars] = groupvars
            else
              results[group[:name].to_sym][:groupvars] = groupvars
            end
          end
          Formatter.out(results)
        end
      end
    end
  end
end
