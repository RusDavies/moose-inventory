require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group addchild" methods of the CLI
      class Group < Thor
        #==========================
        desc 'addchild PARENTGROUP CHILDGROUP_1 [CHILDGROUP_2 ... ]',
             'Associate one or more child-groups CHILDGROUP_n with PARENTGROUP'
        def addchild(*_argv)
          # Sanity check
          if args.length < 2
            abort("ERROR: Wrong number of arguments, #{args.length} "\
              'for 2 or more.')
          end

          # Arguments
          pname = args[0].downcase
          cnames = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Sanity
          if pname == 'ungrouped' || cnames.include?('ungrouped')
            abort("ERROR: Cannot manually manipulate the automatic group 'ungrouped'.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Transaction
          warn_count = 0
          begin
            db.transaction do # Transaction start
              puts "Associate parent group '#{pname}' with child group(s) '#{cnames.join(',')}':"
              # Get the target group
              fmt.puts 2, "- retrieve group '#{pname}'..."
              pgroup = db.models[:group].find(name: pname)
              if pgroup.nil?
                abort("ERROR: The group '#{pname}' does not exist.")
              end
              fmt.puts 4, '- OK'

              # Associate parent group with the child groups

              groups_ds = pgroup.children_dataset
              cnames.each do |cname|
                fmt.puts 2, "- add association {group:#{pname} <-> group:#{cname}}..."

                # Check against existing associations
                unless groups_ds[name: cname].nil?
                  warn_count += 1
                  fmt.warn "Association {group:#{pname} <-> group:#{cname}}}"\
                    " already exists, skipping.\n"
                  fmt.puts 4, '- already exists, skipping.'
                  fmt.puts 4, '- OK'
                  next
                 end

                # Add new association
                cgroup = db.models[:group].find(name: cname)
                if cgroup.nil?
                  warn_count += 1
                  fmt.warn "Group '#{cname}' does not exist and will be created.\n"
                  fmt.puts 4, '- child group does not exist, creating now...'
                  cgroup = db.models[:group].create(name: cname)
                  fmt.puts 6, '- OK'
                end
                pgroup.add_child(cgroup)
                fmt.puts 4, '- OK'
              end
              fmt.puts 2, '- all OK'
            end # Transaction end
          rescue db.exceptions[:moose] => e
            abort("ERROR: #{e}")
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
