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
          if argv.empty?
            abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more.")
          end

          # Arguments
          names = argv.uniq.map(&:downcase)
          options[:hosts] = '' if options[:hosts].nil?
          hosts = options[:hosts].downcase.split(',').uniq

          # sanity
          if names.include?('ungrouped')
            abort("ERROR: Cannot manually manipulate the automatic group 'ungrouped'\n")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

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
                if !hosts_ds.nil? && !hosts_ds[name: h].nil?
                  warn_count += 1
                  fmt.warn "Association {group:#{name} <-> host:#{h}}"\
                    " already exists, skipping creation.\n"
                  fmt.puts 4, '- already exists, skipping.'
                else
                  group.add_host(host)
                end
                fmt.puts 4, '- OK'

                # Handle the host's automatic 'ungrouped' group
                ungrouped = host.groups_dataset[name: 'ungrouped']
                next if ungrouped.nil?
                fmt.puts 2, '- remove automatic association {group:ungrouped'\
                  " <-> host:#{h}}..."
                host.remove_group(ungrouped) unless ungrouped.nil?
                fmt.puts 4, '- OK'
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
