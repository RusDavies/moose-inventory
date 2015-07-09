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
            abort("ERROR: Wrong number of arguments, #{args.length} "\
              "for 2 or more.")
          end

          # Arguments
          name  = args[0].downcase
          hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Sanity
          if name == 'ungrouped'
            abort("ERROR: Cannot manually manipulate the automatic group 'ungrouped'.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Transaction
          warn_count = 0
          begin 
            db.transaction do # Transaction start
              puts "Associate group '#{name}' with host(s) '#{hosts.join(',')}':"
              # Get the target group
              fmt.puts 2, "- retrieve group '#{name}'..."
              group = db.models[:group].find(name: name)
              if group.nil?
                abort("ERROR: The group '#{name}' does not exist.")
              end
              fmt.puts 4,  '- OK'

              # Associate group with the hosts
              ungrouped  = db.models[:group].find_or_create(name: 'ungrouped')
              hosts_ds = group.hosts_dataset
              hosts.each do |h| # rubocop:disable Style/Next
                fmt.puts 2, "- add association {group:#{name} <-> host:#{ h }}..."

                # Check against existing associations
                unless hosts_ds[name: h].nil?
                  warn_count += 1
                  fmt.warn "Association {group:#{name} <-> host:#{ h }} already"\
                    " exists, skipping.\n"
                  fmt.puts 4, '- already exists, skipping.'
                  fmt.puts 4, '- OK'
                  next
                end

                # Add new association
                host = db.models[:host].find(name: h)
                if host.nil?
                  warn_count += 1
                  fmt.warn "Host '#{h}' does not exist and will be created.\n"
                  fmt.puts 4, '- host does not exist, creating now...'
                  host = db.models[:host].create(name: h)
                  fmt.puts 6, '- OK'
                end
                  
                group.add_host(host)
                fmt.puts 4, '- OK'

                # Remove the host from the ungrouped group, if necessary
                unless host.groups_dataset[name: 'ungrouped'].nil?
                  fmt.puts 2,'- remove automatic association '\
                    "{group:ungrouped <-> host:#{h}}..."
                  host.remove_group(ungrouped)
                  fmt.puts 4, '- OK'
                end
              end
              fmt.puts 2, '- all OK'
            end # Transaction end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e.message}")
          end
          if warn_count == 0
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

      end
    end
  end
end
