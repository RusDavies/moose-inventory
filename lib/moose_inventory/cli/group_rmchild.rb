require 'thor'

require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implemention of the "group rmchild" methods of the CLI
      class Group < Thor # rubocop:disable ClassLength
        #==========================
        desc 'rmchild PARENTGROUP CHILDGROUP_1 [CHILDGROUP_2 ... ]',
        'Dissociate one or more child-groups CHILDGROUP_n from PARENTGROUP'
        def rmchild(*argv)

          # Sanity check
          if args.length < 2
            abort("ERROR: Wrong number of arguments, #{args.length} "\
              "for 2 or more.")
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
              puts "Dissociate parent group '#{pname}' from child group(s) '#{cnames.join(',')}':"
              # Get the target group
              fmt.puts 2, "- retrieve group '#{pname}'..."
              pgroup = db.models[:group].find(name: pname)
              if pgroup.nil?
                abort("ERROR: The group '#{pname}' does not exist.")
              end
              fmt.puts 4, "- OK"

              # Dissociate parent group from the child groups
              groups_ds = pgroup.children_dataset
              cnames.each do |cname|
                fmt.puts 2, "- remove association {group:#{pname} <-> group:#{cname}}..."

                # Check against existing associations
                if groups_ds[name: cname].nil?
                  warn_count += 1
                  fmt.warn "Association {group:#{pname} <-> group:#{cname}}"\
                      " does not exist, skipping.\n"
                  fmt.puts 4, "- doesn't exist, skipping."
                  fmt.puts 4, '- OK'
                  next
                end

                # remove association
                cgroup = db.models[:group].find(name: cname)
                pgroup.remove_child(cgroup)
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
