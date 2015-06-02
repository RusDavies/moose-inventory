require 'thor'
require 'json'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'

module Moose
  module Inventory
    module Cli
      class Host < Thor

        #==========================
        desc 'add HOSTNAME_1 [HOSTNAME_2 ...]', 'Add a hosts HOSTNAME_n to the inventory'
        option :groups
        def add(*argv)
          abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more") if argv.length < 1

          names = argv.uniq.map(&:downcase)
          options[:groups] = "ungrouped" if options[:groups].nil? 
          groups = options[:groups].downcase.split(/\W+/).uniq
          abort("ERROR: Cannot manually manipulate the automatic group 'ungrouped'") if groups.include?('ungrouped') && groups.length > 1

          begin
            Sequel::DATABASES[0].transaction do # Transaction start
              names.each do |name|
                print "Adding host #{name}... "
                if !Moose::Inventory::DB::Host.find(:name => name).nil?
                  raise Moose::Inventory::MooseException, "The host '#{name}' already exists in the db."
                end
                host = Moose::Inventory::DB::Host.create(:name => name)
                puts "OK"

                groups.each do |groupname|
                  next if groupname.nil? or groupname.empty?
                  
                  if groupname == 'ungrouped'
                    raise Moose::Inventory::MooseException, "Cannot manually manipulate the automatic group 'ungrouped'."
                  end
                  
                  print "Adding association {host:#{name} <-> group:#{groupname}}..."
                  group = Moose::Inventory::DB::Group.find_or_create(:name => groupname)
                  host.add_group(group)
                  puts "OK"
                end

              end
            end # Transaction end
          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end

          puts "Succeeded"
        end

        #==========================
        desc 'get HOSTNAME_1 [HOSTNAME_2 ...]', 'Get hosts HOSTNAME_n from the inventory'
        def get(*argv)
          abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more") if argv.length < 1

          names = argv.uniq.map(&:downcase)

          results = {}
          names.each do |name|
            host = Moose::Inventory::DB::Host.find(:name => name)

            if !host.nil?
              groups = host.groups_dataset.map(:name)

              hostvars = {}
              host.hostvars_dataset.each { |hv| hostvars[ hv[:name].to_sym ] = hv[:value] }

              results[host[:name].to_sym] = {}
              results[host[:name].to_sym][:groups] = groups unless groups.length == 0
              results[host[:name].to_sym][:hostvars] = hostvars unless hostvars.length == 0
            end
          end

          Moose::Inventory::Cli::Formatter.out(results)

          # TODO: Should not finding any hosts cause an error?
          #abort("Error: No results") if results.length == 0
        end

        #==========================
        desc 'list', 'List the contents of the inventory by host'
        def list
          results = {}
          Moose::Inventory::DB::Host.all.each do |host|
            groups = host.groups_dataset.map(:name)

            hostvars = {}
            host.hostvars_dataset.each {|hv| hostvars[ hv[:name] ] = hv[:value] }

            results[host[:name].to_sym] = {groups: groups}
            results[host[:name].to_sym][:hostvars] = hostvars unless hostvars.length == 0
          end
          Moose::Inventory::Cli::Formatter.out(results)
        end

        #==========================
        desc 'rm HOSTNAME_1 [HOSTNAME_2 ...]', 'Remove hosts HOSTNAME_n from the inventory'
        def rm(*argv)
          abort("ERROR: Wrong number of arguments, #{argv.length} for 1 or more") if argv.length < 1

          names = argv.uniq.map{|item| item.downcase}

          begin
            Sequel::DATABASES[0].transaction do # Transaction start
              names.each do |name|
                print "Removing the host '#{name}'..."
                host = Moose::Inventory::DB::Host.find(name: name)
                if host.nil?
                  raise Moose::Inventory::MooseException, "The host '#{name}' was not found in the db."
                end
                host.remove_all_groups
                host.destroy
              end
            end
          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end
          puts "OK\nSuccess"
        end

        #==========================
        desc 'addgroup HOSTNAME GROUPNAME [GROUPNAME ...]', 'Associate the host with a group'
        def addgroup(*args)
          abort("ERROR: Wrong number of arguments, #{args.length} for 2 or more") if args.length < 2

          # Retrieve our host name and groups list
          name   = args[0].downcase
          groups = args.slice(1, args.length - 1).uniq.map(&:downcase)

          begin
            Sequel::DATABASES[0].transaction do # Transaction start
              # Get the target host
              print "Retrieving host '#{name}'..."
              host = Moose::Inventory::DB::Host.find(name: name)
              if host.nil?
                raise Moose::Inventory::MooseException, "The host '#{name}' was not found in the inventory."
              end
              puts "OK"

              # Associate host with the groups
              groups_ds = host.groups_dataset
              groups.each do |g|
                if g == 'ungrouped'
                  raise Moose::Inventory::MooseException, "Cannot manually manipulate the automatic group 'ungrouped'."
                end
                
                print "Adding association {host:#{name} <-> group:#{ g }}..."

                # Check against existing associations
                if !groups_ds[:name => g].nil?
                  puts "already exists"
                  next
                end

                # Add new association
                group = Moose::Inventory::DB::Group.find_or_create(name: g)
                host.add_group(group)
                puts "OK"
              end

              # Handle 'ungrouped' group automation
              if !groups_ds[:name => "ungrouped"].nil?
                print "Removing automatic association {host:#{name} <-> group:ungrouped}..."
                ungrouped  = Moose::Inventory::DB::Group.find(name: "ungrouped")
                host.remove_group(ungrouped) unless ungrouped.nil?
                puts "OK"
              end
            end # Transaction end

          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end

          puts "Success"
        end

        #==========================
        desc 'rmgroup HOSTNAME GROUPNAME [GROUPNAME ...]', 'dissociation the host from a group'
        def rmgroup(*args)
          abort("ERROR: Wrong number of arguments, #{args.length} for 2 or more") if args.length < 2

          # Retrieve our host name and groups list
          name   = args[0].downcase
          groups = args.slice(1, args.length - 1).uniq.map(&:downcase)

          begin
            Sequel::DATABASES[0].transaction do # Transaction start

              # Get the target host
              print "Retrieving host '#{name}'..."
              host = Moose::Inventory::DB::Host.find(name: name)
              if host.nil?
                raise Moose::Inventory::MooseException, "The host '#{name}' was not found in the inventory."
              end
              puts "OK"

              # dissociate host from the groups
              groups_ds = host.groups_dataset
              groups.each do |g|
                if g == 'ungrouped'
                  raise Moose::Inventory::MooseException, "FAILED: Cannot manually manipulate the automatic group 'ungrouped'."
                end

                print "Removing association {host:#{name} <-> group:#{ g }}..."

                # Check against existing associations
                if !groups_ds[:name => g].nil?
                  puts "does not exist"
                  next
                end

                group = Moose::Inventory::DB::Group.find(name: g)
                host.remove_group(group) unless group.nil?
                puts "OK"
              end

              # Handle 'ungrouped' group automation
              if host.groups_dataset.count == 0
                print "Adding automatic association {host:#{name} <-> group:ungrouped}..."
                ungrouped  = Moose::Inventory::DB::Group.find_or_create(name: "ungrouped")
                host.add_group(ungrouped) unless ungrouped.nil?
              end
            end # End transaction
          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end

          puts "Success"

        end

        #==========================
        desc 'addvar', 'Add a variable to the host'
        def addvar(*args)
          abort("ERROR: Wrong number of arguments, #{args.length} for 2 or more") if args.length < 2

          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq

          begin
            Sequel::DATABASES[0].transaction do # Transaction start
              print "Retrieving host '#{name}'..."
              host = Moose::Inventory::DB::Host.find(name: name)
              if host.nil?
                raise Moose::Inventory::MooseException, "The host '#{name}' was not found in the inventory."
              end
              puts "OK"

              hostvars_ds = host.hostvars_dataset
              vars.each do |v|
                print "Adding hostvar {#{v}}..."
                vararray = v.split('=')
                if vararray.length != 2
                  raise Moose::Inventory::MooseException, "Incorrect format in #{v}.  Expected key=value."
                end

                # Check against existing associations
                hostvar = hostvars_ds[:name => vararray[0]]
                if !hostvar.nil?
                  if hostvar[:value] == vararray[1]
                    puts "already exists"
                    next
                  else
                    print "applying as an update..."
                    update = Moose::Inventory::DB::Hostvar.find(id: hostvar[:id])
                    update[:value] = vararray[1]
                    update.save
                  end
                else
                  hostvar = Moose::Inventory::DB::Hostvar.create(name: vararray[0], value: vararray[1])
                  host.add_hostvar(hostvar)
                end
                puts "OK"
              end
            end # Transaction end

          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end
          puts "Succeeded"
        end

        #==========================
        desc 'rmvar', 'Remove a variable from the host'
        def rmvar(*args)
          abort("ERROR: Wrong number of arguments, #{args.length} for 2 or more") if args.length < 2

          # Retrieve our host name and vars
          name = args[0].downcase
          vars = args.slice(1, args.length - 1).uniq

          begin
            Sequel::DATABASES[0].transaction do # Transaction start
              # Get the target host
              print "Retrieving host '#{name}'..."
              host = Moose::Inventory::DB::Host.find(name: name)
              if host.nil?
                raise Moose::Inventory::MooseException, "The host '#{name}' was not found in the inventory."
              end
              puts "OK"

              # Get the existing hostvars
              hostvars_ds = host.hostvars_dataset
              vars.each do |v|
                print "Removing hostvar {#{v}}..."

                vararray = v.split('=')
                if vararray.length != 1 && vararray.length != 2
                  raise Moose::Inventory::MooseException, "Incorrect format in #{v}.  Expected 'key' or 'key=value'."
                end

                # Check against existing associations
                if hostvars_ds[:name => vararray[0]].nil?
                  puts "does not exist"
                  next
                end

                # remove the association
                host.remove_hostvar(hostvar)
                hostvar.destroy
                puts "OK"
              end
            end
          rescue Moose::Inventory::MooseException => e
            abort("ERROR: #{e.message}")
          end
          puts "Succeeded"
        end
      end
    end
  end
end
