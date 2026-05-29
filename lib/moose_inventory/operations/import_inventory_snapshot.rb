# frozen_string_literal: true

require_relative 'inventory_snapshot_applier'
require_relative 'inventory_snapshot_preview'
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
          @previewer = InventorySnapshotPreview.new(context: context)
        end

        def call(snapshot:)
          normalized = validator.call(snapshot: snapshot)

          context.transaction do
            applier.call(snapshot: normalized)
          end
        end

        def preview(snapshot:)
          normalized = validator.call(snapshot: snapshot)

          previewer.call(snapshot: normalized)
        end

        private

        attr_reader :context, :validator, :applier, :previewer
      end
    end
  end
end
