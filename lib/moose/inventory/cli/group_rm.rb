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

          # Arguments
          names = argv.uniq.map(&:downcase)

          # sanity
          if names.include?('ungrouped')
            abort("Cannot manually manipulate the automatic group 'ungrouped'\n")
          end
            
          # Transaction
          db.transaction do # Transaction start
            names.each do |name|
              puts "Remove the group '#{name}':"
              group = db.models[:group].find(name: name)
              if group.nil?
                warn "  - WARNING: The group '#{ name }' does not exist, skipping."
              else
                # Handle automatic group for any associated hosts
                hosts_ds = group.hosts_dataset
                hosts_ds.each do |host|
                  host_groups_ds = host.groups_dataset
                  if host_groups_ds.count == 1 # We're the only group
                    print "  - Adding automatic association {group:ungrouped <-> host:#{host[:name]}}... "
                    ungrouped = db.models[:group].find_or_create(name: 'ungrouped')
                    host.add_group(ungrouped)
                    puts "OK"
                  end
                end
                # Remove the group
                group.remove_all_hosts
                group.destroy
                puts "  - OK"
              end
            end
          end # Transaction end
          puts "Succeeded"
        end
      end
    end
  end
end
