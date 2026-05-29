# frozen_string_literal: true

require 'json'
require 'thor'
require_relative '../version'
require 'yaml'

require_relative '../config/config'
require_relative '../operations/import_inventory_snapshot'
require_relative '../operations/inventory_doctor'
require_relative '../operations/inventory_snapshot'
require_relative 'formatter'
require_relative 'helpers'
require_relative 'audit'
require_relative 'console'
require_relative 'db'
require_relative 'group'
require_relative 'host'

module Moose
  module Inventory
    module Cli
      ##
      # Top-level Thor application for moose-inventory.
      # rubocop:disable Metrics/ClassLength
      class Application < Thor
        include Moose::Inventory::Cli::Helpers

        desc 'version', 'Get the code version'
        def version
          puts "Version #{Moose::Inventory::VERSION}"
        end

        desc 'doctor', 'Run inventory health checks'
        option :format, type: :string, desc: 'Emit doctor report as yaml|json|pjson'
        def doctor
          report = build_operation(Moose::Inventory::Operations::InventoryDoctor).call
          render_doctor_report(report)
          exit(1) unless report[:ok]
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
        option :preview, type: :boolean, desc: 'Preview snapshot import changes without writing'
        option :preview_format, type: :string, desc: 'Emit preview as yaml|json|pjson'
        def import(file)
          snapshot = YAML.safe_load_file(file, aliases: false)
          operation = build_operation(Moose::Inventory::Operations::ImportInventorySnapshot)
          return render_import_preview(operation.preview(snapshot: snapshot)) if options[:preview]

          abort('ERROR: --preview-format requires --preview.') if options[:preview_format]

          result = operation.call(snapshot: snapshot)
          record_audit({ command: 'import', action: 'import', entity_type: 'inventory',
                         entity_names: file }, result: result)
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

        map 'db' => :database
        desc 'audit ACTION', 'Inspect append-only inventory change history'
        subcommand 'audit', Moose::Inventory::Cli::Audit

        desc 'database ACTION', 'Inspect and manage database lifecycle state'
        subcommand 'database', Moose::Inventory::Cli::Db

        desc 'console', 'Open a small read-only inventory browsing console'
        def console
          Moose::Inventory::Cli::Console.new(context: inventory_context).run
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

        def render_doctor_report(report)
          if options[:format]
            puts serialize_data(report, options[:format].downcase)
          else
            render_human_doctor_report(report)
          end
        end

        def render_human_doctor_report(report)
          if report[:ok]
            puts 'Inventory doctor found no issues.'
            return
          end

          puts "Inventory doctor found #{report[:issue_count]} issue(s):"
          report[:issues].each do |entry|
            puts "- [#{entry[:severity]}] #{entry[:id]}: #{entry[:message]}"
          end
        end

        def render_import_preview(preview)
          if options[:preview_format]
            puts serialize_data(preview, options[:preview_format].downcase)
          else
            render_human_import_preview(preview)
          end
        end

        def render_human_import_preview(preview)
          puts 'Snapshot import preview. No changes applied.'
          preview.fetch('summary').each do |key, value|
            puts "#{key.tr('_', ' ').capitalize}: #{value}"
          end
        end

        def serialize_snapshot(snapshot)
          serialize_data(snapshot, output_format)
        end

        def serialize_data(data, format)
          case format
          when 'yaml', 'y'
            data.to_yaml
          when 'prettyjson', 'pjson', 'p'
            JSON.pretty_generate(data)
          when 'json', 'j'
            data.to_json
          else
            abort("Output format '#{format}' is not yet supported.")
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
