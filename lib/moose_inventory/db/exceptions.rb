module Moose
  module Inventory
    module DB
      ##
      # This class provides a Moose-specific db exception error
      class MooseDBException < RuntimeError
        attr_reader :message
        def initialize(message)
          @message = message || 'An undefined Moose exception occurred'
        end
      end
    end
  end
end
