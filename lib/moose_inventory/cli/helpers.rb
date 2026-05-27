# frozen_string_literal: true

require_relative '../inventory_context'
require_relative 'association_rendering'
require_relative 'factory'
require_relative 'variable_rendering'

module Moose
  module Inventory
    module Cli
      ##
      # Shared helpers for Thor command classes.
      module Helpers
        include Moose::Inventory::Cli::AssociationRendering
        include Moose::Inventory::Cli::VariableRendering

        AUTOMATIC_GROUP = 'ungrouped'

        private

        def db
          Moose::Inventory::DB
        end

        def inventory_context
          @inventory_context ||= Moose::Inventory::InventoryContext.new(db: db)
        end

        def cli_factory
          @cli_factory ||= Moose::Inventory::Cli::Factory.new(context: inventory_context)
        end

        def build_operation(operation_class, **)
          cli_factory.operation(operation_class, **)
        end

        def inventory_query
          cli_factory.query_inventory
        end

        def fmt
          Moose::Inventory::Cli::Formatter
        end

        def runtime_options
          Moose::Inventory::Config.runtime_options
        end

        def output_format
          runtime_options.output_format
        end

        def ansible_mode?
          runtime_options.ansible?
        end

        def normalize_names(values)
          values.uniq.map(&:downcase)
        end

        def csv_option_names(value)
          (value || '').downcase.split(',').uniq
        end

        def abort_if_missing_args(args, minimum, label)
          return unless args.length < minimum

          abort("ERROR: Wrong number of arguments, #{args.length} for #{label}.")
        end

        def abort_if_automatic_group(names, message = nil)
          return unless names.include?(AUTOMATIC_GROUP)

          abort(message || "ERROR: Cannot manually manipulate the automatic group '#{AUTOMATIC_GROUP}'.")
        end

        def association_exists?(dataset, name)
          !dataset.nil? && !dataset[name: name].nil?
        end

        def automatic_group
          inventory_context.automatic_group
        end

        def remove_automatic_group_from_host(host, indent:, message:)
          ungrouped = host.groups_dataset[name: AUTOMATIC_GROUP]
          return if ungrouped.nil?

          fmt.puts indent, message
          host.remove_group(ungrouped)
          fmt.puts indent + 2, '- OK'
        end

        def add_automatic_group_to_host_if_last_group(host, indent:, message:)
          add_automatic_group_to_host_if_group_count(host, 1, indent: indent, message: message)
        end

        def add_automatic_group_to_host_if_no_groups(host, indent:, message:)
          add_automatic_group_to_host_if_group_count(host, 0, indent: indent, message: message)
        end

        def add_automatic_group_to_host_if_group_count(host, group_count, indent:, message:)
          return unless host.groups_dataset.count == group_count

          fmt.puts indent, message
          host.add_group(automatic_group)
          fmt.puts indent + 2, '- OK'
        end
      end
    end
  end
end
