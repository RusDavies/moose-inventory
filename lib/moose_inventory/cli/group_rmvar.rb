require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Implementation of the "group rmvar" method of the CLI
      class Group
        #==========================
        desc 'rmvar NAME VARNAME',
             'Remove a variable VARNAME from the group NAME'
        def rmvar(*args)
          if args.length < 2
            abort('ERROR: Wrong number of arguments, ' \
                  "#{args.length} for 2 or more.")
          end
          
          # Convenience
          db  = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq

          # Transaction
          db.transaction do # Transaction start
            puts "Remove variable(s) '#{vars.join(",")}' from group '#{name}':"
            
            fmt.puts 2, "- retrieve group '#{name}'..."
            group = db.models[:group].find(name: name)
            if group.nil?
              fail db.exceptions[:moose],
                   "The group '#{name}' does not exist."
            end
            fmt.puts 4, '- OK'
            
            groupvars_ds = group.groupvars_dataset
            vars.each do |v|
              fmt.puts 2, "- remove variable '#{v}'..."
              vararray = v.split('=')
              if v.start_with?('=') || v.scan('=').count > 1
                fail db.exceptions[:moose],
                     "Incorrect format in {#{v}}. " \
                     'Expected \'key\' or \'key=value\'.'
              end
            
              # Check against existing associations
              groupvar = groupvars_ds[name: vararray[0]]
              unless groupvar.nil?
                # remove the association
                group.remove_groupvar(groupvar)
                groupvar.destroy
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
