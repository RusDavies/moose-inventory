require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "addgroup" method of the CLI
      class Host
        desc 'addgroup HOSTNAME GROUPNAME [GROUPNAME ...]',
             'Associate the host with a group'
        # rubocop:disable Metrics/LineLength
        def addgroup(*args) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          # rubocop:enable Metrics/LineLength
          # Sanity
          if args.length < 2
            abort('ERROR: Wrong number of arguments, '\
              "#{args.length} for 2 or more.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          name   = args[0].downcase
          groups = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Sanity
          if groups.include?('ungrouped')
            abort 'ERROR: Cannot manually manipulate the automatic '\
              'group \'ungrouped\'.'
          end 
          
          # Transaction
          db.transaction do # Transaction start
            puts "Associate host '#{name}' with groups '#{groups.join(',')}':" 
            # Get the target host
            fmt.puts 2, "- Retrieve host '#{name}'..."
            host = db.models[:host].find(name: name)
            if host.nil?
              fail db.exceptions[:moose], "The host '#{name}' "\
                'was not found in the database.'
            end
            fmt.puts 4, '- OK'

            # Associate host with the groups
            groups_ds = host.groups_dataset
            groups.each do |g|
              fmt.puts 2,  "- Add association {host:#{name} <-> group:#{ g }}..."

              # Check against existing associations
              if !groups_ds[name: g].nil?
                fmt.warn "Association {host:#{name} <-> group:#{g}} already exists, skipping."
                fmt.puts 4,  "- Already exists, skipping."
              else
                # Add new association
                group = db.models[:group].find(name: g)
                if group.nil?
                  fmt.warn "Group '#{g}' does not exist and will be created."
                  fmt.puts 4,  "- Group does not exist, creating now..."
                  group = db.models[:group].create(name: g)
                  fmt.puts 6,  "- OK"
                end
                host.add_group(group)
              end
              fmt.puts 4, '- OK'
            end

            # Handle 'ungrouped' group automation
            unless groups_ds[name: 'ungrouped'].nil?
              fmt.puts 2,  '- Remove automatic association '\
                "{host:#{name} <-> group:ungrouped}..."
              ungrouped  = db.models[:group].find(name: 'ungrouped')
              host.remove_group(ungrouped) unless ungrouped.nil?
              fmt.puts 4, '- OK'
            end
            fmt.puts 2, '- All OK'
          end # Transaction end
          puts 'Succeeded'
        end
      end
    end
  end
end
