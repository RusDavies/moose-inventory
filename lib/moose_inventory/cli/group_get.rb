require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group get" method of the CLI
      class Group
        desc 'get GROUP_1 [GROUP_2 ...]', 'Get groups GROUP_n from the inventory'
        def get(*argv) # rubocop:disable Metrics/AbcSize
          if argv.empty?
            abort('ERROR: Wrong number of arguments, '\
              "#{argv.length} for 1 or more")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          names = argv.uniq.map(&:downcase)

          # Process
          results = {}
          names.each do |name|
            group = db.models[:group].find(name: name)

            next if group.nil?
            hosts = group.hosts_dataset.map(:name)

            children = group.children_dataset.map(:name)

            groupvars = {}
            group.groupvars_dataset.each do |gv|
              groupvars[gv[:name].to_sym] = gv[:value]
            end

            results[group[:name].to_sym] = {}
            results[group[:name].to_sym][:hosts] = hosts unless hosts.empty?

            unless children.empty?
              results[group[:name].to_sym][:children] = children
            end

            unless groupvars.empty?
              results[group[:name].to_sym][:groupvars] = groupvars
            end
          end

          fmt.dump(results)
        end
      end
    end
  end
end
