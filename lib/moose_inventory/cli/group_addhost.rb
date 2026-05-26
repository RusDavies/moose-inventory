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
          abort_if_missing_args(args, 2, '2 or more')

          # Arguments
          name  = args[0].downcase
          hosts = normalize_names(args.slice(1, args.length - 1))

          # Sanity
          abort_if_automatic_group([name])

          # Transaction
          warn_count = 0
          begin
            db.transaction do # Transaction start
              puts "Associate group '#{name}' with host(s) '#{hosts.join(',')}':"
              # Get the target group
              fmt.puts 2, "- retrieve group '#{name}'..."
              group = db.models[:group].find(name: name)
              abort("ERROR: The group '#{name}' does not exist.") if group.nil?
              fmt.puts 4, '- OK'

              # Associate group with the hosts
              hosts_ds = group.hosts_dataset
              hosts.each do |h|
                fmt.puts 2, "- add association {group:#{name} <-> host:#{h}}..."

                # Check against existing associations
                if association_exists?(hosts_ds, h)
                  warn_count += 1
                  fmt.warn "Association {group:#{name} <-> host:#{h}} already"\
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
                remove_automatic_group_from_host(
                  host,
                  indent: 2,
                  message: '- remove automatic association '\
                    "{group:ungrouped <-> host:#{h}}..."
                )
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
