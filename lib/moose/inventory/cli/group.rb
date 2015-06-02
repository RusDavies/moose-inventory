require 'thor'
require_relative './formatter.rb'

module Moose
  module Inventory
    module Cli
      class Group < Thor
        desc 'add NAME', 'Add a group NAME to the inventory'
        option :hosts
        def add(name)
          name = name.downcase
          abort("Can't add automatic group 'ungrouped'") if name=='ungrouped'
          
          print "Attempting to add group #{name}... "
          abort("FAILED: The group '#{name}' already exists in the db.") unless Moose::Inventory::DB::Group.find(:name => name).nil?
          newGroupEntry = Moose::Inventory::DB::Group.create(:name => name)
          puts "OK"

          if !options[:hosts].nil?
            options[:hosts].downcase.split(/\W+/).uniq.each do |h|
              print "Adding association {group:#{name} <-> host:#{ h }}..."
              h.strip!
              next if h.nil? or h.empty?
              newHostEntry = Moose::Inventory::DB::Host.find_or_create(:name => h) 
              newGroupEntry.add_host(newHostEntry)
              puts "OK"
            end
          end
          puts "Succeeded"
        end

        desc 'get NAME', 'Get a group NAME from the inventory'
        def get(name)
          name = name.downcase

          group = Moose::Inventory::DB::Group.find(:name => name)
          
          results = {}
          if !group.nil?
            hosts = group.hosts_dataset.map(:name)
            groupvars = {}
            group.groupvars_dataset.each { |gv| groupvars[ gv[:name].to_sym ] = gv[:value] }

            results[group[:name].to_sym] = {}
            results[group[:name].to_sym][:hosts]     = hosts     unless hosts.length == 0
            results[group[:name].to_sym][:groupvars] = groupvars unless groupvars.length == 0

            Moose::Inventory::Cli::Formatter.out(results)
          else
            Moose::Inventory::Cli::Formatter.out(results)
            abort("No results")
          end
        end
        
        desc 'list', 'List the groups, together with any associated hosts and groupvars'
        option :ansiblestyle, :type => :boolean
        def list
          results = {}
          Moose::Inventory::DB::Group.all.each do |group|
            hosts = group.hosts_dataset.map(:name)

            groupvars = {}
            group.groupvars_dataset.each {|gv| groupvars[ gv[:name] ] = gv[:value] }

            results[group[:name].to_sym] = {hosts: hosts}
            results[group[:name].to_sym][:groupvars] = groupvars unless groupvars.length == 0
          end
          Moose::Inventory::Cli::Formatter.out(results)
        end

        desc 'rm NAME', 'Remove a group NAME from the inventory'
        def rm(name)
          name = name.downcase
          abort("Can't remove automatic group 'ungrouped'") if name=='ungrouped'

          print "Attempting to remove the group '#{name}'..."
          group = Moose::Inventory::DB::Group.find(name: name)
          abort("FAILED: The group '#{ name }' was not found in the database.") if group.nil?

          group.remove_all_hosts
          group.destroy

          puts "OK\nSuccess"
        end

        desc 'addchild [options] NAME CHILDNAME', 'Associate a child-group CHILDNAME with the group NAME'
        option :allowcreate, :type => :boolean
        def addchild
          abort("The 'groups addchild GROUP' method is not yet implemented")
          puts "group addchild"
        end

        desc 'rmchild NAME CHILDNAME', 'Dissociate a child-group CHILDNAME from the group NAME'
        def rmchild
          abort("The 'groups rmchild GROUP' method is not yet implemented")
          puts "group rmchild"
        end

        desc 'addhost NAME HOSTNAME', 'Associate a host HOSTNAME with the group NAME'
        def addhost(*args)
          raise ArgumentError, "Wrong number of arguments, #{args.length} for 2 or more" if args.length < 2

          # Retrieve our group name and hosts list
          name  = args[0].downcase
          hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Get the target group
          print "Retrieving group '#{name}'..."
          group = Moose::Inventory::DB::Group.find(name: name)
          abort("FAILED: The group '#{name}' was not found in the inventory.") if group.nil?
          puts "OK"

          # Associate group with the hosts
          ungrouped  = Moose::Inventory::DB::Group.find(name: "ungrouped")
          hosts_ds = group.hosts_dataset
          hosts.each do |h|
            print "Adding association {group:#{name} <-> host:#{ h }}..."

            # Check against existing associations
            if ! hosts_ds[:name => h].nil?
              puts "already exists"
              next
            end

            # Add new association
            host = Moose::Inventory::DB::Host.find_or_create(name: h)
            group.add_host(host)
            puts "OK"

            # Remove the host from the ungrouped group, if necessary
            if !host.groups_dataset[:name => "ungrouped"].nil?
              print "Removing association {host:#{h} <-> group:ungrouped}..."
              host.remove_group(ungrouped)
              puts "OK"
            end
          end

          puts "Success"
        end

        desc 'rmhost GROUPNAME HOSTNAME_1 [HOSTNAME_2 ...]', 'Dissociate the hosts HOSTNAME_n from the group NAME'
        def rmhost(*args)
          raise ArgumentError, "Wrong number of arguments, #{args.length} for 2 or more" if args.length < 2
          
          # Retrieve our host name and groups list
          name   = args[0].downcase
          abort("Can't remove hosts from automatic group 'ungrouped'") if name=='ungrouped'
          hosts = args.slice(1, args.length - 1).uniq.map(&:downcase)

          # Get the target group
          print "Retrieving group '#{name}'..."
          group = Moose::Inventory::DB::Group.find(name: name)
          abort("FAILED: The group '#{name}' was not found in the inventory.") if group.nil?
          puts "OK"

          # dissociate group from the hosts
          ungrouped  = Moose::Inventory::DB::Group.find_or_create(name: "ungrouped")
          hosts_ds = group.hosts_dataset
          hosts.each do |h|
            print "Removing association {group:#{name} <-> host:#{ h }}..."

            # Check against existing associations
            if hosts_ds[:name => h].nil?
               puts "does not exist"
               next 
            end

            host = Moose::Inventory::DB::Host.find(name: h)
            group.remove_host(host) unless host.nil?
            puts "OK"
            
            # Add the host to the ungrouped group if not in any other group
            if host.groups_dataset[:name => "ungrouped"].nil? 
              print "Adding association {host:#{h} <-> group:ungrouped}..."
              host.add_group(ungrouped)
              puts "OK"
            end
          end
          
          puts "Success" 
        end

        desc 'addvar NAME VARNAME=VALUE', 'Add a variable VARNAME with value VALUE to the group NAME'
        def addvar
          puts "group addvar"
        end

        desc 'rmvar NAME VARNAME', 'Remove a variable VARNAME from the group NAME'
        def rmvar
          puts "group rmvar"
        end
      end
    end
  end
end
