# frozen_string_literal: true

require 'thor'
require 'json'

require_relative 'formatter'

module Moose
  module Inventory
    module Cli
      # Database lifecycle commands.
      class Db < Thor
        desc 'status', 'Show database lifecycle status'
        def status
          render_status(Moose::Inventory::DB.status)
        end

        desc 'doctor', 'Check database schema state'
        def doctor
          status = Moose::Inventory::DB.status
          missing = status[:tables].reject { |_name, present| present }.keys
          if missing.empty? && status[:schema_version] == status[:expected_schema_version]
            puts 'Database doctor found no issues.'
            return
          end

          puts 'Database doctor found issue(s):'
          puts "- Missing tables: #{missing.join(', ')}" unless missing.empty?
          if status[:schema_version] != status[:expected_schema_version]
            puts "- Schema version is #{status[:schema_version].inspect}; expected #{status[:expected_schema_version]}."
          end
          exit(1)
        end

        desc 'migrate', 'Create missing schema tables and record current schema version'
        def migrate
          status = Moose::Inventory::DB.migrate!
          puts "Database schema is at version #{status[:schema_version]}."
        end

        desc 'backup FILE', 'Back up the configured sqlite3 database file'
        def backup(file)
          destination = Moose::Inventory::DB.backup(file)
          puts "Backed up database to #{destination}."
        rescue Moose::Inventory::DB.exceptions[:moose] => e
          abort("ERROR: #{e.message}")
        end

        private

        def render_status(status)
          puts "Adapter: #{status[:adapter]}"
          puts "Schema version: #{status[:schema_version] || 'unknown'}"
          puts "Expected schema version: #{status[:expected_schema_version]}"
          puts "SQLite file: #{status[:sqlite_file]}" unless status[:sqlite_file].nil?
          puts 'Tables:'
          status[:tables].each do |name, present|
            puts "- #{name}: #{present ? 'present' : 'missing'}"
          end
        end
      end
    end
  end
end
