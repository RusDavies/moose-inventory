# frozen_string_literal: true

module Moose
  module Inventory
    module Operations
      class QueryInventory
        # Shared helpers for query subcomponents.
        class BaseQuery
          def initialize(context:)
            @context = context
          end

          private

          attr_reader :context

          def variables_hash(dataset)
            dataset.order(:id).to_h { |variable| [variable[:name].to_sym, variable[:value]] }
          end
        end
      end
    end
  end
end
