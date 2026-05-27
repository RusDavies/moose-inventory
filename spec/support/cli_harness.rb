# frozen_string_literal: true

module CliHarness
  def setup_cli_harness(command_class:, command_ivar: nil, include_cli: false, extra_commands: {})
    @mockarg_parts = {
      config: File.join(spec_root, 'config/config.yml'),
      format: 'yaml',
      env: 'test'
    }
    @mockargs = build_cli_args(@mockarg_parts)

    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @console = Moose::Inventory::Cli::Formatter
    @db = Moose::Inventory::DB
    @db.init if @db.db.nil?

    @app = Moose::Inventory::Cli::Application
    @cli = Moose::Inventory::Cli if include_cli
    instance_variable_set(command_ivar, command_class) unless command_ivar.nil?
    extra_commands.each { |ivar, klass| instance_variable_set(ivar, klass) }
  end

  def reset_cli_harness(reset_config: false)
    @config.init(@mockargs) if reset_config
    @db.reset
  end

  def build_cli_args(parts)
    parts.flat_map { |key, value| ["--#{key}", value] }
  end
end
