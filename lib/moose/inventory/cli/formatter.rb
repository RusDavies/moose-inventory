require "json"
require "yaml"

module Moose
  module Inventory
    module Cli
      module Formatter
        extend self
        def self.out(arg)

          return if arg.nil?

          format = Moose::Inventory::Config._confopts[:format].downcase
          case format
          when "yaml"
            puts arg.to_yaml

          when "prettyjson"
            puts JSON.pretty_generate(arg)

          when "json"
            puts arg.to_json

          else
            abort("Output format '#{format}' is not yet supported.")
          end
        end
      end
    end
  end
end