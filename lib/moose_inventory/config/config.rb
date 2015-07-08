# Configuration

require 'yaml'

module Moose
  module Inventory
    ##
    # This Modules manages application-wide configuration options
    module Config
      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      @_argv     = []
      @_confopts = {}
      @_settings = {}

      attr_reader :_argv
      attr_reader :_confopts
      attr_reader :_settings

      #----------------------
      def self.init(args)
        @_argv = args.dup

        top_level_help
        top_level_args
        ansible_args
        resolve_config_file
        load
      end

      #----------------------
      def self.top_level_args
        # Certain top level flags affect the configuration.
        # --config FILE  => sets the configuration file to be used.
        #                   Default is to search standard locations.
        # --env ENV      => sets the section to be used as the configuration.
        #                   Defaults to ""
        # --format FORMAT=> See formatter for supported types.
        #                   Defaults to json.

        @_confopts = { env: '', format: 'json', trace: false }

        # The following are a O(n^m) approach.  TODO: O(n) version?
          
        # Check for two-part flags   
        %w(env config format).each do |var|
          @_argv.each_with_index do |val, index|
            next if val != "--#{var}"
            @_confopts[var.to_sym] = @_argv[index + 1]
            1.downto(0) { |offset| @_argv.delete_at(index + offset) }
            break
          end
        end
        
        # Check for one-part flags
        %w(trace).each do |var|
          @_argv.each_with_index do |val, index|
            next if val != "--#{var}"
            @_confopts[var.to_sym] = true
            @_argv.delete_at(index)
            break
          end
        end
        
      end

      #----------------------
      def self.top_level_help
        if @_argv[0] == 'help'
          puts "Global flags:"
          printf "  %-31s %-10s", "--config FILE", "# Specifies a configuration file to use\n"
          printf "  %-31s %-10s", "--env ENV", "# Specifies the environment section of the config to use\n"
          printf "  %-31s %-10s", "--format yaml|json|pjson", "# Format for the output of 'get' and 'list'\n"
          puts "\nAnsible flags:"
          printf "  %-31s %-10s", "--hosts", "# Retrieves the list of hosts (alias for 'host list'\n"
          printf "  %-31s %-10s", "--hosts HOST", "# Retrieves the specified host (alias for 'host get HOST')\n"
          printf "  %-31s %-10s", "--groups", "# Retrieves the list of groups (alias for 'group list')\n\n"
        end
      end
      
      #----------------------
      def self.ansible_args  # rubocop:disable Metrics/AbcSize
        # Handle Ansible flags
        # --hosts           => host list
        # --hosts HOSTNAME  => host get HOSTNAME
        # --groups          => lgroup list

        if @_argv[0] == '--hosts'
          host = @_argv[1]
          if !host.nil?
            @_argv.clear
            ['host', 'get', "#{host}"].each do |arg|
              @_argv << arg
            end
          else
            @_argv.clear
            ['host', 'list'].each do |arg|
              @_argv << arg
            end
          end
        elsif @_argv[0] == '--groups'
          @_argv.clear
          ['group', 'list'].each do |arg|
            @_argv << arg
          end
        end
      end

      #----------------------
      def self.resolve_config_file # rubocop:disable Metrics/AbcSize
        if ! @_confopts[:config].nil?
          path = File.expand_path(@_confopts[:config])
          if File.exist?(path)
            @_confopts[:config] = path
          else
            fail("The configuration file #{path} does not exist")
          end
        else
          possibles = ['./.moose-tools/inventory/config',
                       '~/.moose-tools/inventory/config',
                       '~/local/etc/moose-tools/inventory/config',
                       '/etc/moose-tools/inventory/config'
                      ]
          possibles.each do |f|
            file = File.expand_path(f)
            @_confopts[:config] = file if File.exist?(file)
          end
        end

        if @_confopts[:config].nil?
          fail('No configuration either given or found in standard locations.')
        end
      end

      #----------------------
      def self.symbolize_keys(hash)
        # rubocop:disable Style/EachWithObject
        hash.inject({}) do |result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        end
        # rubocop:enable Style/EachWithObject
      end

      #----------------------
      # rubocop:disable PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
      def self.load
        newsets = symbolize_keys(YAML.load_file(@_confopts[:config]))

        path = @_confopts[:config]

        # Get the "general" section
        @_settings[:general] = newsets[:general]
        @_settings[:general].nil? && fail("Missing 'general' root in #{path}")

        # Get the config for the correct environment

        if @_confopts[:env] && !@_confopts[:env].empty?
          env = @_confopts[:env]
          @_settings[:config] = newsets[@_confopts[:env].to_sym]
        else
          env  = @_settings[:general][:defaultenv]
          (env.nil? || env.empty?) && fail("No defaultenv set in #{path}")
          @_settings[:config] = newsets[env.to_sym]
        end

        @_settings[:config].nil? && fail("Missing '#{env}' root in #{path}")

        # And now we should have a valid config stuffed into @_options[:config]
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize
    end
  end
end
