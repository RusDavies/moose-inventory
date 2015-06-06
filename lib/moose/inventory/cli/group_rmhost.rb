require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group rmhost" method of the CLI
      class Group

        #==========================
        desc 'rmhost GROUPNAME HOSTNAME_1 [HOSTNAME_2 ...]',
             'Dissociate the hosts HOSTNAME_n from the group NAME'
        # rubocop:disable Metrics/LineLength
        def rmhost(*args) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/LineLength
          # Sanity
          if args.length < 2
            fail ArgumentError,
                 "Wrong number of arguments, #{args.length} for 2 or more"
          end

          # Convenience
          db    = Moose::Inventory::DB

          # Transaction
          begin
            db.transaction do # Transaction start
              # Retrieve our host name and groups list
              name   = args[0].downcase
              if name == 'ungrouped'
                abort("Can't remove hosts from automatic group 'ungrouped'")
              end
              hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

              # Get the target group
              print "Retrieving group '#{name}'..."
              group = db.models[:group].find(name: name)
              if group.nil?
                abort("FAILED: The group '#{name}' was not found '\
                  'in the inventory.")
              end
              puts 'OK'

              # dissociate group from the hosts
              ungrouped  = db.models[:group].find_or_create(name: 'ungrouped')
              hosts_ds = group.hosts_dataset
              hosts.each do |h| # rubocop:disable Style/Next
                print "Removing association {group:#{name} <-> host:#{ h }}..."

                # Check against existing associations
                if hosts_ds[name: h].nil?
                  puts 'does not exist'
                  next
                end

                host = db.models[:host].find(name: h)
                group.remove_host(host) unless host.nil?
                puts 'OK'

                # Add the host to the ungrouped group if not in any other group
                if host.groups_dataset[name: 'ungrouped'].nil?
                  print "Adding association {host:#{h} <-> group:ungrouped}..."
                  host.add_group(ungrouped)
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
