require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group addvar" method of the CLI
      class Group
        #==========================
        desc 'addvar NAME VARNAME=VALUE',
             'Add a variable VARNAME with value VALUE to the group NAME'
        def addvar(*args)
          if args.length < 2
            abort('ERROR: Wrong number of arguments, '\
              "#{args.length} for 2 or more.")
          end
          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq
          
        # Transaction
        db.transaction do # Transaction start
          puts "Add variables '#{vars.join(",")}' to group '#{name}':"
          fmt.puts 2,"- retrieve group '#{name}'..."
          group = db.models[:group].find(name: name)
          if group.nil?
            fail db.exceptions[:moose],
                 "The group '#{name}' does not exist."
          end
          fmt.puts 4, '- OK'

          groupvars_ds = group.groupvars_dataset
          vars.each do |v|
            fmt.puts 2, "- add variable '#{v}'..."
            vararray = v.split('=')

            if v.start_with?('=') ||  v.end_with?('=') || vararray.length != 2
              fail db.exceptions[:moose],
                   "Incorrect format in '{#{v}}'. Expected 'key=value'."
            end
 
            # Check against existing associations
            groupvar = groupvars_ds[name: vararray[0]]
            if !groupvar.nil?
              unless groupvar[:value] == vararray[1]
                fmt.puts 4, '- already exists, applying as an update...'
                update = db.models[:groupvar].find(id: groupvar[:id])
                update[:value] = vararray[1]
                update.save
              end
            else
              # groupvar doesn't exist, so create and associate
              groupvar = db.models[:groupvar].create(name: vararray[0],
                                                    value: vararray[1])
              group.add_groupvar(groupvar)
            end
            fmt.puts 4, '- OK'
          end
          fmt.puts 2, '- all OK'
        end # Transaction end

        puts 'Succeeded.'
        end
      end
    end
  end
end
