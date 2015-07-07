require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of "group rm" methods of the CLI
      class Group

        #==========================
        desc 'rm NAME',
             'Remove a group NAME from the inventory'
        def rm(*argv) # rubocop:disable Metrics/AbcSize
          #
          # Sanity
          if argv.length < 1
               abort('ERROR: Wrong number of arguments, '\
                 "#{argv.length} for 1 or more.")
           end          
          
          # Convenience
          db    = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          names = argv.uniq.map(&:downcase)

          # sanity
          if names.include?('ungrouped')
            abort("Cannot manually manipulate the automatic group 'ungrouped'\n")
          end
            
          # Transaction
          warn_count = 0
          db.transaction do # Transaction start
            names.each do |name|
              puts "Remove group '#{name}':"
              fmt.puts 2, "- Retrieve group '#{name}'..."
              group = db.models[:group].find(name: name)
              if group.nil?
                warn_count += 1
                fmt.warn "Group '#{ name }' does not exist, skipping.\n"
                fmt.puts 4, "- No such group, skipping."
              end
              fmt.puts 4, "- OK" 
              unless group.nil?
                # Handle automatic group for any associated hosts
                hosts_ds = group.hosts_dataset
                hosts_ds.each do |host|
                  host_groups_ds = host.groups_dataset
                  if host_groups_ds.count == 1 # We're the only group
                    fmt.puts 2, "- Adding automatic association {group:ungrouped <-> host:#{host[:name]}}..."
                    ungrouped = db.models[:group].find_or_create(name: 'ungrouped')
                    host.add_group(ungrouped)
                    fmt.puts 4, "- OK"
                  end
                end
                # Remove the group
                fmt.puts 2, "- Destroy group '#{name}'..."
                group.remove_all_hosts
                group.destroy
                fmt.puts 4, "- OK"
              end
              fmt.puts 2, "- All OK"
            end
          end # Transaction end
          if warn_count == 0
            puts "Succeeded."
          else
            puts "Succeeded, with warnings."
          end
        end
      end
    end
  end
end
