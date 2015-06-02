require 'yaml'

module Moose
  module Inventory
    module Config
      extend self
      @_argv     = []
      @_confopts = {}
      @_settings = {}

      attr_reader :_argv
      attr_reader :_confopts
      attr_reader :_settings
 
      #----------------------
      def self.init(args)
        @_argv = args.dup

        self.get_top_level_args
        #self.get_ansible_args
        self.resolve_config_file
        self.load
      end

      #----------------------
      def self.get_top_level_args  
        
        # Certain top level flags affect the configuration.
        # --config FILE  => sets the configuration file to be used. Default is to search standard locations.
        # --env ENV      => sets the section to be used as the configuration. Defaults to ""
        # --format FORMAT=> See formatter for supported types.  Defaults to json.
        @_confopts = {env: "", format: "json"}

        ["env", "config", "format"].each do |var|
          @_argv.each_with_index do |val, index|
            if val == "--#{var}"
              @_confopts[var.to_sym] = @_argv[index + 1]
              1.downto(0) {|offset| @_argv.delete_at(index + offset)}
              break
            end
          end
        end
      end

      #----------------------
      def self.get_ansible_args 
        # Look for Ansible --hosts flag in the primary position, and adapt accordingly
        # Recover Ansible-style flags from the arguments, and adapt accordingly.
        # --hosts           => list all hosts
        # --hosts HOSTNAME  => get host name
        # --groups          => list all groups

        if @_argv[0] == "--hosts"
          host = @_argv[1]
          if !host.nil?
            @_argv.clear
            ["host", "get", "#{host}", "--ansiblestyle"].each {|arg| @_argv << arg}
          else
            @_argv.clear
            ["host", "list", "--ansiblestyle"].each {|arg| @_argv << arg}
          end
        elsif @_argv[0] == "--groups"
          ["group", "list", "--ansiblestyle"].each {|arg| @_argv << arg}
        end  
      end 

      #---------------------- 
      def self.resolve_config_file()

        if !@_confopts[:config].nil?
          @_confopts[:config] = File.expand_path(@_confopts[:config])
          fail("The configuration file #{options[:config]} does not exist") unless File.exists?(@_confopts[:config])
        else
          possibles = ["./.moose-tools/inventory/config",
            "~/.moose-tools/inventory/config",
            "~/local/etc/moose-tools/inventory/config",
            "/etc/moose-tools/inventory/config"]
          possibles.each do |f|
            file = File.expand_path(f)
            @_confopts[:config] = file if File.exists?(file)
          end
        end

        fail("No configuration either given or found in standard locations.") if @_confopts[:config].nil?
      end

      #----------------------
      def self.symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|
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
        }
      end

      #----------------------
      def self.load
        newsets = self.symbolize_keys(YAML::load_file(@_confopts[:config]))

        # Get the "general" section
        @_settings[:general] = newsets[:general]
        fail("Missing 'general' root in #{@_confopts[:config]}") if @_settings[:general].nil?

        # Get the config for the correct environment
        if @_confopts[:env] && !@_confopts[:env].empty?
          @_settings[:config] = newsets[@_confopts[:env].to_sym]
          fail("Missing '#{@_confopts[:env]}' root in #{@_confopts[:config]}") if @_settings[:config].nil?
        else
          fail("No defaultenv set in #{@_confopts[:config]}") if @_settings[:general][:defaultenv].nil?
          @_settings[:config] = newsets[@_settings[:general][:defaultenv].to_sym]
          fail("Missing '#{@_settings[:general][:defaultenv]}' root in #{@_confopts[:config]}") if @_settings[:config].nil?
        end

        # And now we should have a valid config stuffed into @_options[:config]
      end
    end
  end
end
