# frozen_string_literal: true

module Moose
  module Inventory
    ##
    # Thin facade over the current DB singleton.
    #
    # This gives new operation/service objects a small inventory-facing seam
    # without forcing the legacy CLI to stop using the DB singleton all at once.
    class InventoryContext
      AUTOMATIC_GROUP = 'ungrouped'

      def initialize(db: Moose::Inventory::DB)
        @db = db
      end

      def transaction(&)
        db.transaction(&)
      end

      def find_host(name)
        db.models[:host].find(name: name)
      end

      def create_host(name)
        db.models[:host].create(name: name)
      end

      def find_group(name)
        db.models[:group].find(name: name)
      end

      def create_group(name)
        db.models[:group].create(name: name)
      end

      def find_or_create_group(name)
        db.models[:group].find_or_create(name: name)
      end

      def automatic_group
        find_or_create_group(AUTOMATIC_GROUP)
      end

      def find_variable(entity_type, id)
        db.models[variable_model_key(entity_type)].find(id: id)
      end

      def create_variable(entity_type, name:, value:)
        db.models[variable_model_key(entity_type)].create(name: name, value: value)
      end

      def moose_exception_class
        db.exceptions[:moose]
      end

      private

      def variable_model_key(entity_type)
        :"#{entity_type}var"
      end

      attr_reader :db
    end
  end
end
