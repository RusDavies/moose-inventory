# frozen_string_literal: true

module Moose
  module Inventory
    # Small value object for resolved runtime CLI options.
    class RuntimeOptions
      attr_reader :argv, :config, :env, :format

      def initialize(argv:, config:, env:, format:, flags:)
        @argv = argv
        @config = config
        @env = env
        @format = format
        @ansible = flags[:ansible] == true
        @trace = flags[:trace] == true
      end

      def ansible?
        @ansible
      end

      def trace?
        @trace
      end

      def output_format
        format.to_s.downcase
      end
    end
  end
end
