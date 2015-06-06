require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host rmvar" method of the CLI
      class Host
        #==========================
        desc 'rmvar', 'Remove a variable from the host'
        # rubocop:disable Metrics/LineLength
        def rmvar(*args) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
          # rubocop:enableMetrics/LineLength
          if args.length < 2
            abort('ERROR: Wrong number of arguments, ' \
                  "#{args.length} for 2 or more.")
          end

          # Convenience
          db    = Moose::Inventory::DB

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
              print "Removing hostvar {#{v}}... "
              vararray = v.split('=')
              if v.start_with?('=') || v.scan('=').count > 1
                fail db.exceptions[:moose],
                     "Incorrect format in {#{v}}. " \
                     'Expected \'key\' or \'key=value\'.'
              end

              # Check against existing associations
              hostvar = hostvars_ds[name: vararray[0]]
              unless hostvar.nil?
                # remove the association
                host.remove_hostvar(hostvar)
                hostvar.destroy
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
