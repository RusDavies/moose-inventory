require 'thor'
require 'json'
require 'indentation'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'
 
module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "host" methods of the CLI
      class Host
        #==========================
        desc 'add HOSTNAME_1 [HOSTNAME_2 ...]',
             'Add a hosts HOSTNAME_n to the inventory'
        option :groups
        # rubocop:disable Metrics/LineLength
        def add(*argv) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          # rubocop:enable Metrics/LineLength
          if argv.length < 1
            abort('ERROR: Wrong number of arguments, '\
              "#{argv.length} for 1 or more.")
          end

          # Convenience
          db = Moose::Inventory::DB
          fmt = Moose::Inventory::Cli::Formatter
          
          # Arguments
          names = argv.uniq.map(&:downcase)

          # split(/\W+/) splits on hyphens too, which is not what we want
          #groups = options[:groups].downcase.split(/\W+/).uniq
          options[:groups].nil? && options[:groups] = ''  
          groups = options[:groups].downcase.split(',').uniq

          # Sanity
          if groups.include?('ungrouped')
            abort("ERROR: Cannot manually manipulate "\
              "the automatic group 'ungrouped'.")
          end

          # Process
          db.transaction do # Transaction start
            fmt.reset_indent
              
            names.each do |name|
              puts "Add host '#{name}':"
              fmt.puts 2, "- Creating host '#{name}'..."
              host = db.models[:host].find(name: name)
              groups_ds = nil
              if host.nil?
                host = db.models[:host].create(name: name)
              else
                fmt.warn "The host '#{name}' already exists, skipping creation.\n"
                groups_ds = host.groups_dataset
              end
              fmt.puts 4, "- OK"
              
              groups.each do |g|
                next if g.nil? || g.empty?
                fmt.puts 2, "- Adding association {host:#{name} <-> group:#{g}}..."
                group = db.models[:group].find(name: g)
                if group.nil?
                  fmt.warn "The group '#{g}' doesn't exist, but will be created.\n"
                  group = db.models[:group].create(name: g)
                end
                if !groups_ds.nil? && groups_ds[name: g].nil?
                  fmt.warn "Association {host:#{name} <-> group:#{ g }} already exists, skipping creation.\n"
                else
                  host.add_group(group)
                end
                fmt.puts 4, '- OK'
              end
              
              # Handle the automatic 'ungrouped' group
              groups_ds = host.groups_dataset
              if !groups_ds.nil?  && groups_ds.count == 0
                  fmt.puts 2, "- Adding automatic association {host:#{name} <-> group:ungrouped}..."
                  ungrouped = db.models[:group].find_or_create(name: 'ungrouped')
                  host.add_group(ungrouped)
                  fmt.puts 4, "- OK"
              end
              fmt.puts 2, "- All OK"
            end
          end # Transaction end
          puts 'Succeeded'
        end
      end
    end
  end
end
