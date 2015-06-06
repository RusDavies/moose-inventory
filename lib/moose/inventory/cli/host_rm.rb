require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host rm" method of the CLI
      class Host
        #==========================
        desc 'rm HOSTNAME_1 [HOSTNAME_2 ...]',
             'Remove hosts HOSTNAME_n from the inventory'
        def rm(*argv) # rubocop:disable Metrics/AbcSize
          #
          # Sanity
          if argv.length < 1
            abort('ERROR: Wrong number of arguments, '\
              "#{argv.length} for 1 or more.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter
          
          # Arguments
          names = argv.uniq.map(&:downcase)

          # Transaction
          warn_count = 0
          db.transaction do # Transaction start
            names.each do |name|
              puts "Remove host '#{name}':"
              fmt.puts 2, "- Retrieve host '#{name}'..."
              host = db.models[:host].find(name: name)
              if host.nil?
                warn_count += 1
                fmt.warn "Host '#{name}' does not exist, skipping.\n"
                fmt.puts 4, "- No such host, skipping."
              end
              fmt.puts 4, "- OK"
              unless host.nil?
                fmt.puts 2, "- Destroy host '#{name}'..."
                host.remove_all_groups
                host.destroy
                fmt.puts 4, "- OK"
              end
              fmt.puts 2, "- All OK"
            end
          end # Transaction end
          if warn_count == 0 
            puts "Succeeded."
          else
            puts "Succeeded, with warnings."
          end
        end
      end
    end
  end
end
