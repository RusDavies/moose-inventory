require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host addvar" method of the CLI
      class Host
        #==========================
        desc 'addvar', 'Add a variable to the host'
        # rubocop:disable Metrics/LineLength
        def addvar(*args) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          # rubocop:enable Metrics/LineLength
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
            puts "Add variables '#{vars.join(",")}' to host '#{name}':"
            fmt.puts 2,"- retrieve host '#{name}'..."
            host = db.models[:host].find(name: name)
            if host.nil?
              fail db.exceptions[:moose],
                   "The host '#{name}' does not exist."
            end
            fmt.puts 4, '- OK'

            hostvars_ds = host.hostvars_dataset
            vars.each do |v|
              fmt.puts 2, "- add variable '#{v}'..."
              vararray = v.split('=')
              if v.start_with?('=') ||  v.end_with?('=') || vararray.length != 2
                fail db.exceptions[:moose],
                     "Incorrect format in '{#{v}}'. Expected 'key=value'."
              end
                
              # Check against existing associations
              hostvar = hostvars_ds[name: vararray[0]]
              if !hostvar.nil?
                unless hostvar[:value] == vararray[1]
                  fmt.puts 4, '- already exists, applying as an update...'
                  update = db.models[:hostvar].find(id: hostvar[:id])
                  update[:value] = vararray[1]
                  update.save
                end
              else
                # hostvar doesn't exist, so create and associate
                hostvar = db.models[:hostvar].create(name: vararray[0],
                                                      value: vararray[1])
                host.add_hostvar(hostvar)
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
