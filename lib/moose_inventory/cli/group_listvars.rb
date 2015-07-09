require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      ##
      # implementation of the "group listvars" method of the CLI
      class Group
        #==========================
        desc 'listvar', 'List all variables associated with the group'
        def listvars(*argv)
          # Convenience
          confopts = Moose::Inventory::Config._confopts

          # Note, the Ansible spects don't call for a "--group GROUPNAME" method.
          # So, strictly, there is no Ansible compatibility for this method.
          # Instead, the Ansible compatibility included herein is for consistency
          # with the "hosts listvars" method, which services the Ansible 
          # "--host HOSTNAME" specs.
                     
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
            group = db.models[:group].find(name: name)
            if group.nil?
              fmt.warn "The Group #{name} does not exist."
            else
              group.groupvars_dataset.each do |gv|
                results[gv[:name].to_sym] = gv[:value]
              end
            end
          else
            # This our more flexible implementation
            names.each do |name|
              group = db.models[:group].find(name: name)
              unless group.nil?
                results[name.to_sym] = {}
                group.groupvars_dataset.each do |gv|
                  results[name.to_sym][gv[:name].to_sym] = gv[:value]
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
