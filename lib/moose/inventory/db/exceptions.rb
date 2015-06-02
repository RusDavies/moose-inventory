module Moose
  module Inventory
    module DB
      class MooseDBException < RuntimeError
        attr :message
        def initialize(message)
          @message = message || "An undefined Moose exception occurred"
        end
      end
    end
  end
end