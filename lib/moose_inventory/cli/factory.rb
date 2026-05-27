# frozen_string_literal: true

require_relative '../operations/query_inventory'

module Moose
  module Inventory
    module Cli
      # Small factory for command-side operations and query wrappers.
      class Factory
        def initialize(context:)
          @context = context
        end

        def operation(operation_class, **)
          operation_class.new(context: context, **)
        end

        def query_inventory
          @query_inventory ||= Moose::Inventory::Operations::QueryInventory.new(context: context)
        end

        private

        attr_reader :context
      end
    end
  end
end
