# frozen_string_literal: true

module Moose
  module Inventory
    module DB
      ##
      # This class provides a Moose-specific db exception error
      class MooseDBException < RuntimeError
        DEFAULT_MESSAGE = 'An undefined Moose exception occurred'

        def initialize(message = nil)
          super(message || DEFAULT_MESSAGE)
        end
      end
    end
  end
end
