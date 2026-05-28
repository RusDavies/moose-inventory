# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared transaction/fetch helpers for host/group relation commands.
      module RelationTransactionSupport
        private

        def fetch_existing_group_or_abort(name)
          fmt.puts 2, "- retrieve group '#{name}'..." unless machine_plan_output_requested?
          group = inventory_context.find_group(name)
          abort("ERROR: The group '#{name}' does not exist.") if group.nil?

          fmt.puts 4, '- OK' unless machine_plan_output_requested?
          group
        end

        def fetch_existing_host_or_raise(name)
          fmt.puts 2, "- Retrieve host '#{name}'..." unless machine_plan_output_requested?
          host = inventory_context.find_host(name)
          raise db.exceptions[:moose], "The host '#{name}' was not found in the database." if host.nil?

          fmt.puts 4, '- OK' unless machine_plan_output_requested?
          host
        end

        def run_group_relation_transaction(heading:, on_error: nil, &)
          run_relation_transaction(heading: heading, all_ok_message: '- all OK', on_error: on_error, &)
        end

        def run_host_relation_transaction(heading:, on_error: nil, &)
          run_relation_transaction(heading: heading, all_ok_message: '- All OK', on_error: on_error, &)
        end

        def run_relation_transaction(heading:, all_ok_message:, on_error: nil)
          result = nil
          db.transaction do
            puts heading unless machine_plan_output_requested?
            result = yield
            fmt.puts 2, all_ok_message unless machine_plan_output_requested?
          end
          result
        rescue db.exceptions[:moose] => e
          message = on_error ? on_error.call(e) : e.message
          abort("ERROR: #{message}")
        end
      end
    end
  end
end
