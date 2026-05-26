module Moose
  module Inventory
    ##
    # Thin facade over the current DB singleton.
    #
    # This gives new operation/service objects a small inventory-facing seam
    # without forcing the legacy CLI to stop using the DB singleton all at once.
    class InventoryContext
      AUTOMATIC_GROUP = 'ungrouped'.freeze

      def initialize(db: Moose::Inventory::DB)
        @db = db
      end

      def transaction(&block)
        db.transaction(&block)
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

      private

      attr_reader :db
    end
  end
end
