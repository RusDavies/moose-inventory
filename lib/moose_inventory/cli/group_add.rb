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
          abort_if_missing_args(argv, 1, '1 or more')

          # Arguments
          names = normalize_names(argv)
          hosts = csv_option_names(options[:hosts])

          # sanity
          abort_if_automatic_group(
            names,
            "ERROR: Cannot manually manipulate the automatic group 'ungrouped'\n"
          )

          # Transaction
          warn_count = 0
          db.transaction do # Transaction start
            names.each do |name|
              # Add the group
              puts "Add group '#{name}':"
              group = db.models[:group].find(name: name)
              hosts_ds = nil
              fmt.puts 2, '- create group...'
              if group.nil?
                group = db.models[:group].create(name: name)
                fmt.puts 4, '- OK'
              else
                warn_count += 1
                fmt.warn "Group '#{name}' already exists, skipping creation.\n"
                fmt.puts 4, '- already exists, skipping.'
                hosts_ds = group.hosts_dataset
                fmt.puts 4, '- OK'
              end

              # Associate with hosts
              hosts.each do |h|
                next if h.nil? || h.empty?
                fmt.puts 2, "- add association {group:#{name} <-> host:#{h}}..."
                host = db.models[:host].find(name: h)
                if host.nil?
                  warn_count += 1
                  fmt.warn "Host '#{h}' doesn't exist, but will be created.\n"
                  fmt.puts 4, "- host doesn't exist, creating now..."
                  host = db.models[:host].create(name: h)
                  fmt.puts 6, '- OK'
                end
                if association_exists?(hosts_ds, h)
                  warn_count += 1
                  fmt.warn "Association {group:#{name} <-> host:#{h}}"\
                    " already exists, skipping creation.\n"
                  fmt.puts 4, '- already exists, skipping.'
                else
                  group.add_host(host)
                end
                fmt.puts 4, '- OK'

                # Handle the host's automatic 'ungrouped' group
                remove_automatic_group_from_host(
                  host,
                  indent: 2,
                  message: '- remove automatic association {group:ungrouped'\
                    " <-> host:#{h}}..."
                )
              end
              fmt.puts 2, '- all OK'
            end
          end # Transaction end
          if warn_count == 0
            puts 'Succeeded'
          else
            puts 'Succeeded, with warnings.'
          end
        end
      end
    end
  end
end
