# frozen_string_literal: true

require 'thor'
require_relative '../version'
require 'yaml'

require_relative '../config/config'
require_relative '../operations/import_inventory_snapshot'
require_relative '../operations/inventory_snapshot'
require_relative 'formatter'
require_relative 'group'
require_relative 'helpers'
require_relative 'host'

module Moose
  module Inventory
    module Cli
      ##
      # Top-level Thor application for moose-inventory.
      class Application < Thor
        include Moose::Inventory::Cli::Helpers

        desc 'version', 'Get the code version'
        def version
          puts "Version #{Moose::Inventory::VERSION}"
        end

        desc 'export [FILE]', 'Export a canonical inventory snapshot'
        def export(file = nil)
          snapshot = build_operation(Moose::Inventory::Operations::InventorySnapshot).export
          output = serialize_snapshot(snapshot)

          if file.nil?
            puts output
          else
            File.write(file, output)
            puts "Exported inventory snapshot to #{file}."
          end
        end

        desc 'import FILE', 'Import and validate an inventory snapshot'
        def import(file)
          snapshot = YAML.safe_load_file(file, aliases: false)
          result = build_operation(Moose::Inventory::Operations::ImportInventorySnapshot).call(snapshot: snapshot)
          puts "Imported inventory snapshot from #{file}."
          puts "Created hosts: #{result.created_hosts}"
          puts "Created groups: #{result.created_groups}"
          puts "Variables changed: #{result.updated_variables}"
          puts "Associations added: #{result.associations}"
        rescue Psych::SyntaxError => e
          abort("ERROR: Could not parse inventory snapshot '#{file}': #{e.message}")
        rescue db.exceptions[:moose] => e
          abort("ERROR: #{e.message}")
        end

        desc 'group ACTION',
             'Manipulate groups in the inventory. ' \
             'ACTION can be add, rm, get, list, addhost, rmhost, addchild, rmchild, addvar, rmvar'
        subcommand 'group', Moose::Inventory::Cli::Group

        desc 'host ACTION',
             'Manipulate hosts in the inventory. ' \
             'ACTION can be add, rm, get, list, addgroup, rmgroup, addvar, rmvar'
        subcommand 'host', Moose::Inventory::Cli::Host

        private

        def serialize_snapshot(snapshot)
          case output_format
          when 'yaml', 'y'
            snapshot.to_yaml
          when 'prettyjson', 'pjson', 'p'
            JSON.pretty_generate(snapshot)
          when 'json', 'j'
            snapshot.to_json
          else
            abort("Output format '#{output_format}' is not yet supported.")
          end
        end
      end
    end
  end
end
