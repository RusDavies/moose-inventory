# frozen_string_literal: true

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

      @_argv = []
      @_confopts = {}
      @_settings = {}

      attr_reader :_argv, :_confopts, :_settings

      #----------------------
      def self.init(args)
        reset_runtime_state
        @_argv = args.dup

        top_level_help
        top_level_args
        ansible_args
        resolve_config_file
        load
      end

      def self.reset_runtime_state
        @_argv = []
        @_confopts = default_confopts
        @_settings = {}
      end

      def self.default_confopts
        { env: '', format: 'json', ansible: false, trace: false }
      end

      #----------------------
      def self.top_level_args
        # The following top-level flags affect the global configuration.
        #
        # --ansible      => forces ansible mode in relevant responders
        #                   Default is not use to use ansible mode
        #
        # --config FILE  => sets the configuration file to be used.
        #                   Default is to search standard locations.
        #
        # --env ENV      => sets the section to be used as the configuration.
        #                   Defaults to "", which forces the use of the
        #                   defaultenv parameter from the general section of
        #                   the config file.
        #
        # --format FORMAT=> See formatter for supported types.
        #                   Defaults to json.
        #
        # -- trace       => Enable more complete exceptions for db transactions
        #                   Default is not to trace.

        extract_value_flags(%w[config env format])
        extract_boolean_flags(%w[ansible trace])
        normalize_ansible_format!
      end

      #----------------------
      def self.top_level_help
        return unless @_argv[0] == 'help'

        puts 'Global flags:'
        printf '  %-31s %-10s', '--ansible', "# Force Ansible mode (automatically set when using ansible flags)\n"
        printf '  %-31s %-10s', '--config FILE', "# Specifies a configuration file to use\n"
        printf '  %-31s %-10s', '--env ENV', "# Specifies the environment section of the config to use\n"
        printf '  %-31s %-10s', '--format yaml|json|pjson',
               "# Format for the output of 'get', 'list', and 'listvars' subcommands\n"
        printf '  %-31s %-10s', '--trace', "# Enable more complete exception dumps for database transactions\n"
        puts "\nAnsible flags:"
        printf '  %-31s %-10s', '--host HOSTNAME',
               "# Retrieves host variables for the specified host (alias for 'host listvars HOSTNAME')\n"
        printf '  %-31s %-10s', '--list', "# Retrieves the list of groups (alias for 'group list')\n\n"
      end

      #----------------------
      def self.ansible_args
        #
        # See http://docs.ansible.com/developing_inventory.html for Ansible specs
        # for dynamic inventory sources

        # --list            => group list
        # --host HOSTNAME  => host getvars HOSTNAME

        case @_argv[0]
        when '--list'
          apply_ansible_alias!(%w[group list])
        when '--host'
          host = @_argv[1]
          apply_ansible_alias!(['host', 'listvars', host.to_s])
        end
      end

      #----------------------
      def self.resolve_config_file
        explicit_path = @_confopts[:config]
        @_confopts[:config] = if explicit_path.nil?
                                find_default_config_file
                              else
                                validated_config_path(explicit_path)
                              end

        raise('No configuration either given or found in standard locations.') if @_confopts[:config].nil?
      end

      #----------------------
      def self.symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[symbolize_key(key)] = value.is_a?(Hash) ? symbolize_keys(value) : value
        end
      end

      #----------------------
      def self.load
        newsets = load_config_file(@_confopts[:config])
        path = @_confopts[:config]

        @_settings[:general] = fetch_general_settings(newsets, path)

        env, settings = resolve_environment_settings(newsets, path)
        @_settings[:config] = settings
        @_settings[:config].nil? && raise("Missing '#{env}' root in #{path}")
      end

      def self.load_config_file(path)
        symbolize_keys(YAML.safe_load_file(
                         path,
                         aliases: false,
                         permitted_classes: [],
                         permitted_symbols: []
                       ))
      end

      def self.fetch_general_settings(newsets, path)
        general = newsets[:general]
        general.nil? && raise("Missing 'general' root in #{path}")
        general
      end

      def self.resolve_environment_settings(newsets, path)
        env = selected_environment(newsets, path)
        [env, newsets[env.to_sym]]
      end

      def self.selected_environment(newsets, path)
        return @_confopts[:env] if @_confopts[:env] && !@_confopts[:env].empty?

        env = newsets.dig(:general, :defaultenv)
        (env.nil? || env.empty?) && raise("No defaultenv set in #{path}")
        env
      end

      def self.standard_config_paths
        ['./.moose-tools/inventory/config',
         '~/.moose-tools/inventory/config',
         '~/local/etc/moose-tools/inventory/config',
         '/etc/moose-tools/inventory/config']
      end

      def self.find_default_config_file
        standard_config_paths.map { |path| File.expand_path(path) }.find do |path|
          File.exist?(path)
        end
      end

      def self.validated_config_path(path)
        expanded = File.expand_path(path)
        raise("The configuration file #{expanded} does not exist") unless File.exist?(expanded)

        expanded
      end

      def self.extract_value_flags(flags)
        flags.each { |flag| extract_value_flag(flag) }
      end

      def self.extract_value_flag(flag)
        index = @_argv.index("--#{flag}")
        return if index.nil?

        @_confopts[flag.to_sym] = @_argv[index + 1]
        @_argv.slice!(index, 2)
      end

      def self.extract_boolean_flags(flags)
        flags.each { |flag| extract_boolean_flag(flag) }
      end

      def self.extract_boolean_flag(flag)
        index = @_argv.index("--#{flag}")
        return if index.nil?

        @_confopts[flag.to_sym] = true
        @_argv.delete_at(index)
      end

      def self.normalize_ansible_format!
        return unless @_confopts[:ansible] == true
        return if @_confopts[:format] =~ /p|pjson|j|json/

        @_confopts[:format] = 'json'
      end

      def self.apply_ansible_alias!(argv)
        @_confopts[:ansible] = true
        normalize_ansible_format!
        @_argv = argv
      end

      def self.symbolize_key(key)
        key.is_a?(String) ? key.to_sym : key
      end
    end
  end
end
