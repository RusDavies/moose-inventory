require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation the "host rmgroup" methods of the CLI
      class Host
        #==========================
        desc 'rmgroup HOSTNAME GROUPNAME [GROUPNAME ...]',
             'dissociation the host from a group'
        # rubocop:disable Metrics/LineLength
        def rmgroup(*args) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          # rubocop:enable Metrics/LineLength
          if args.length < 2
            abort('ERROR: Wrong number of arguments, '\
                  "#{args.length} for 2 or more.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # arguments
          name   = args[0].downcase
          groups = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Sanity
          if groups.include?('ungrouped')
            abort 'ERROR: Cannot manually manipulate the automatic '\
              'group \'ungrouped\'.'
          end

          # Transaction
          db.transaction do # Transaction start
            puts "Dissociate host '#{name}' from groups '#{groups.join(',')}':"
            fmt.puts 2, "- Retrieve host '#{name}'..."
            host = db.models[:host].find(name: name)
            if host.nil?
              fail db.exceptions[:moose],
                   "The host '#{name}' was not found in the database."
            end
            fmt.puts 4, '- OK'

            # dissociate host from the groups
            groups_ds = host.groups_dataset
            groups.each do |g|
              fmt.puts 2, "- Remove association {host:#{name} <-> group:#{g}}..."

              # Check against existing associations
              if groups_ds[name: g].nil?
                fmt.warn "Association {host:#{name} <-> group:#{g}} doesn't exist, skipping.\n"
                fmt.puts 4, "- Doesn't exist, skipping."
              else
                group = db.models[:group].find(name: g)
                host.remove_group(group) unless group.nil?
              end
              fmt.puts 4, '- OK'
            end

            # Handle 'ungrouped' group automation
            if host.groups_dataset.count == 0
              fmt.puts 2, '- Add automatic association '\
                "{host:#{name} <-> group:ungrouped}..."
              ungrouped = db.models[:group].find_or_create(name: 'ungrouped')
              host.add_group(ungrouped) unless ungrouped.nil?
              fmt.puts 4, '- OK'
            end
            fmt.puts 2, '- All OK'
          end # End transaction
          puts 'Succeeded'
        end
      end
    end
  end
end
