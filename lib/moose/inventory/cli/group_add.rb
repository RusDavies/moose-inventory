require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group add" method of the CLI
      class Group
        #==========================
        desc 'add NAME', 'Add a group NAME to the inventory'
        option :hosts
        # rubocop:disable Metrics/LineLength
        def add(*argv) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/LineLength
          if argv.length < 1
            abort('ERROR: Wrong number of arguments, '\
              "#{argv.length} for 1 or more.")
          end

          # Convenience
          db    = Moose::Inventory::DB

          # Arguments
          names = argv.uniq.map(&:downcase)
          options[:hosts] = '' if options[:hosts].nil?
            
          # split(/\W+/) splits on hyphens too, which is not what we want.
          #hosts = options[:hosts].downcase.split(/\W+/).uniq
          hosts = options[:hosts].downcase.split(',').uniq

          # sanity
          if names.include?('ungrouped')
            abort("Cannot manually manipulate the automatic group 'ungrouped'\n")
          end

          # Transaction
          db.transaction do # Transaction start
            names.each do |name|
              # Add the group
              print "Adding group #{name}... "
              group = db.models[:group].find(name: name)
              hosts_ds = nil
              if group.nil?
                group = db.models[:group].create(name: name)
              else
                warn "WARNING: The group '#{name}' already exists, "\
                  "skipping creation."
                hosts_ds = group.hosts_dataset
              end
              puts 'OK'
              
              # Associate with hosts
              hosts.each do |h|
                next if h.nil? || h.empty?
                print "Adding association {group:#{name} <-> host:#{ h }}... "
                host = db.models[:host].find(name: h)
                if host.nil?
                  warn ("WARNING: The host '#{h}' doesn't exist, "\
                    "but will be created.")
                  host = db.models[:host].create(name: h)
                end
                if !hosts_ds.nil? && !hosts_ds[name: h].nil?
                  warn "WARNING: The association {group:#{name} <-> host:#{ h }}"\
                    " already exists, skipping creation."
                else  
                  group.add_host(host)
                end
                puts 'OK'
  
                # Handle the host's automatic 'ungrouped' group
                ungrouped = host.groups_dataset[name: 'ungrouped']
                unless ungrouped.nil?
                  print "Removing automatic association {group:ungrouped <-> host:#{ h }}... "
                  host.remove_group( ungrouped ) unless ungrouped.nil?
                  puts 'OK'
                end
              end
            end
          end # Transaction end
          puts 'Succeeded'
        end
      end
    end
  end
end

