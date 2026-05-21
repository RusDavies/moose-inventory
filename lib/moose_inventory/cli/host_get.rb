require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "host get" method of the CLI
      class Host
        require_relative 'host_add'

        #==========================
        desc 'get HOST_1 [HOST_2 ...]',
             'Get hosts HOST_n from the inventory'
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
            host = db.models[:host].find(name: name)

            next if host.nil?
            groups = host.groups_dataset.map(:name)

            hostvars = {}
            host.hostvars_dataset.each do |hv|
              hostvars[hv[:name].to_sym] = hv[:value]
            end

            results[host[:name].to_sym] = {}
            results[host[:name].to_sym][:groups] = groups unless groups.empty?
            unless hostvars.empty?
              results[host[:name].to_sym][:hostvars] = hostvars
            end
          end

          fmt.dump(results)
        end
      end
    end
  end
end
