require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of "group rm" methods of the CLI
      class Group
        #==========================
        option :recursive,
               type: :boolean,
               default: false,
               desc: 'Also delete child groups that become orphaned'
        desc 'rm NAME',
             'Remove a group NAME from the inventory'
        def rm(*argv) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          #
          # Sanity
          if argv.empty?
            abort('ERROR: Wrong number of arguments, '\
              "#{argv.length} for 1 or more.")
           end

          # Convenience
          db = Moose::Inventory::DB
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
                fmt.warn "Group '#{name}' does not exist, skipping.\n"
                fmt.puts 4, '- No such group, skipping.'
              end
              fmt.puts 4, '- OK'
              unless group.nil?
                # Dissociate from any parent groups
                pgroups_ds = group.parents_dataset
                pgroups_ds.each do |parent|
                  fmt.puts 2, "- Remove association {group:#{name} <-> group:#{parent.name}}..."
                  parent.remove_child(group)
                  fmt.puts 4, '- OK'
                end

                # Dissociate from any child groups
                groups_ds = group.children_dataset
                groups_ds.each do |child|
                  fmt.puts 2, "- Remove association {group:#{name} <-> group:#{child.name}}..."
                  group.remove_child(child)
                  fmt.puts 4, '- OK'
                  delete_orphaned_group(child, db, fmt) if options[:recursive]
                end

                # Remove the group
                destroy_group(group, db, fmt)
              end
              fmt.puts 2, '- All OK'
            end
          end # Transaction end
          if warn_count == 0
            puts 'Succeeded.'
          else
            puts 'Succeeded, with warnings.'
          end
        end

        private

        def delete_orphaned_group(group, db, fmt)
          return if group.name == 'ungrouped'
          return unless group.parents_dataset.count.zero?

          fmt.puts 2, "- Recursively delete orphaned group '#{group.name}'..."
          group.children_dataset.each do |child|
            fmt.puts 4, "- Remove association {group:#{group.name} <-> group:#{child.name}}..."
            group.remove_child(child)
            fmt.puts 6, '- OK'
            delete_orphaned_group(child, db, fmt)
          end
          destroy_group(group, db, fmt, indent: 4)
        end

        def destroy_group(group, db, fmt, indent: 2)
          group.hosts_dataset.each do |host|
            host_groups_ds = host.groups_dataset
            next unless host_groups_ds.count == 1 # We're the only group

            fmt.puts indent,
                     "- Adding automatic association {group:ungrouped <-> host:#{host[:name]}}..."
            ungrouped = db.models[:group].find_or_create(name: 'ungrouped')
            host.add_group(ungrouped)
            fmt.puts indent + 2, '- OK'
          end

          fmt.puts indent, "- Destroy group '#{group.name}'..."
          group.remove_all_groupvars
          group.remove_all_hosts
          group.destroy
          fmt.puts indent + 2, '- OK'
        end
      end
    end
  end
end
