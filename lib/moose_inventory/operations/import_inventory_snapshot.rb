# frozen_string_literal: true

require_relative 'inventory_snapshot_applier'
require_relative 'inventory_snapshot_validator'

module Moose
  module Inventory
    module Operations
      # Validates and imports a portable inventory snapshot.
      class ImportInventorySnapshot
        Result = InventorySnapshotApplier::Result

        def initialize(context:)
          @context = context
          @validator = InventorySnapshotValidator.new(context: context)
          @applier = InventorySnapshotApplier.new(context: context)
        end

        def call(snapshot:)
          normalized = validator.call(snapshot: snapshot)

          context.transaction do
            applier.call(snapshot: normalized)
          end
        end

        private

        attr_reader :context, :validator, :applier
      end
    end
  end
end
