# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      ##
      # Shared helpers for Thor command classes.
      module Helpers
        AUTOMATIC_GROUP = 'ungrouped'

        private

        def db
          Moose::Inventory::DB
        end

        def fmt
          Moose::Inventory::Cli::Formatter
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
          db.models[:group].find_or_create(name: AUTOMATIC_GROUP)
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
