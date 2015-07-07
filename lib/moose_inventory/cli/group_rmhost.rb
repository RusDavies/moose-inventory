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
            abort("ERROR: Wrong number of arguments, #{args.length} for 2 or more.")
          end

          # Arguments 
          name = args[0].downcase
          hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Sanity
          if name == 'ungrouped'
            abort("ERROR: Cannot manually manipulate the automatic group 'ungrouped'.")
          end

          # Convenience
          db    = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Transaction
          warn_count = 0
          begin
            db.transaction do # Transaction start
              # Get the target group
              puts "Dissociate group '#{name}' from host(s) '#{hosts.join(',')}':"
              fmt.puts 2, "- retrieve group '#{name}'..."
              group = db.models[:group].find(name: name)
              if group.nil?
                abort("ERROR: The group '#{name}' does not exist.")
              end
              fmt.puts 4, '- OK'

              # dissociate group from the hosts
              ungrouped  = db.models[:group].find_or_create(name: 'ungrouped')
              hosts_ds = group.hosts_dataset
              hosts.each do |h| # rubocop:disable Style/Next
                fmt.puts 2, "- remove association {group:#{name} <-> host:#{ h }}..."

                # Check against existing associations
                if hosts_ds[name: h].nil?
                  warn_count += 1
                  fmt.warn "Association {group:#{name} <-> host:#{ h }} doesn't"\
                    " exist, skipping.\n"
                  fmt.puts 4, '- doesn\'t exist, skipping.'
                  fmt.puts 4, '- OK'
                  next
                end

                host = db.models[:host].find(name: h)
                group.remove_host(host) unless host.nil?
                fmt.puts 4,'- OK'

                # Add the host to the ungrouped group if not in any other group
                if host.groups_dataset.count == 0
                  fmt.puts 2, "- add automatic association {group:ungrouped <-> host:#{h}}..."
                  host.add_group(ungrouped)
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
