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

          # Arguments
          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq

          # Transaction
          db.transaction do # Transaction start
            print "Retrieving host '#{name}'... "
            host = db.models[:host].find(name: name)
            if host.nil?
              fail db.exceptions[:moose],
                   "The host '#{name}' was not found in the database."
            end
            puts 'OK'

            hostvars_ds = host.hostvars_dataset
            vars.each do |v|
              print "Adding hostvar {#{v}}... "
              vararray = v.split('=')
              if v.start_with?('=') ||  v.end_with?('=') || vararray.length != 2
                fail db.exceptions[:moose],
                     "Incorrect format in {#{v}}. Expected 'key=value'."
              end

              # Check against existing associations
              hostvar = hostvars_ds[name: vararray[0]]
              if !hostvar.nil?
                # hostvar exists
                unless hostvar[:value] == vararray[1]
                  # existing hostvar has wrong value, so update.  
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
              puts 'OK'
            end
          end # Transaction end

          puts 'Succeeded'
        end
      end
    end
  end
end
