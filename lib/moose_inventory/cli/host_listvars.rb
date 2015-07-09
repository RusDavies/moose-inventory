require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "host listvars" method of the CLI
      class Host
        #==========================
        desc 'listvar', 'List all variables associated with the host'
        def listvars(*argv)
          # Convenience
          confopts = Moose::Inventory::Config._confopts
          
          # sanity
          if confopts[:ansible] == true
            if argv.length != 1
            abort('ERROR: Wrong number of arguments for Ansible mode, '\
                  "#{args.length} for 1.")
            end
          else
            if argv.length < 1
              abort('ERROR: Wrong number of arguments, '\
                    "#{args.length} for 1 or more.")
            end
          end


          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter

          # Arguments
          names = argv.uniq.map(&:downcase)

          #process
          results = {}
            
          if confopts[:ansible] == true 
            # This is the implementation per Ansible specs
            name = names.first
            host = db.models[:host].find(name: name)
            if host.nil?
              fmt.warn "The host #{name} does not exist.\n"
            else
              host.hostvars_dataset.each do |hv|
                results[hv[:name].to_sym] = hv[:value]
              end
            end
          else
            # This our more flexible implementation, which is not  compatible 
            # with the Ansible specs 
            names.each do |name|
              host = db.models[:host].find(name: name)
              unless host.nil?
                results[name.to_sym] = {}
                host.hostvars_dataset.each do |hv|
                  results[name.to_sym][hv[:name].to_sym] = hv[:value]
                end
              end
            end
          end
          fmt.dump(results)
        end
      end
    end
  end
end
