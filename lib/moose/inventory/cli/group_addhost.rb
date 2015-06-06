require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group addhost" method of the CLI
      class Group
        #==========================
        desc 'addhost NAME HOSTNAME',
             'Associate a host HOSTNAME with the group NAME'
        def addhost(*args) # rubocop:disable Metrics/AbcSize
          # Sanity
          if args.length < 2
            fail ArgumentError,
                 "Wrong number of arguments, #{args.length} for 2 or more"
          end

          # Convenience
          db    = Moose::Inventory::DB

          # Arguments
          name  = args[0].downcase
          hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Transaction
          begin
            db.transaction do # Transaction start
              # Get the target group
              print "Retrieving group '#{name}'..."
              group = db.models[:group].find(name: name)
              if group.nil?
                abort('FAILED: The group '\
                  "'#{name}' was not found in the inventory.")
              end
              puts 'OK'

              # Associate group with the hosts
              ungrouped  = db.models[:group].find(name: 'ungrouped')
              hosts_ds = group.hosts_dataset
              hosts.each do |h| # rubocop:disable Style/Next
                print "Adding association {group:#{name} <-> host:#{ h }}..."

                # Check against existing associations
                unless hosts_ds[name: h].nil?
                  puts 'already exists'
                  next
                end

                # Add new association
                host = db.models[:host].find_or_create(name: h)
                group.add_host(host)
                puts 'OK'

                # Remove the host from the ungrouped group, if necessary
                unless host.groups_dataset[name: 'ungrouped'].nil?
                  print 'Removing association '\
                    "{host:#{h} <-> group:ungrouped}..."
                  host.remove_group(ungrouped)
                  puts 'OK'
                end
              end
            end # Transaction end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e.message}")
          end
          puts 'Success'
        end

      end
    end
  end
end
