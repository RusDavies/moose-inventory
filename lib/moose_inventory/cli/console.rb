# frozen_string_literal: true

require 'shellwords'

module Moose
  module Inventory
    module Cli
      # Small read-only interactive console for browsing inventory state.
      class Console
        COMMANDS = ['help', 'hosts', 'groups', 'host NAME', 'group NAME',
                    'tags host NAME', 'tags group NAME', 'audit [LIMIT]', 'quit'].freeze

        def initialize(context:, input: $stdin, output: $stdout)
          @context = context
          @input = input
          @output = output
        end

        def run
          output.puts 'Moose Inventory console (read-only). Type help or quit.'
          input.each_line do |line|
            parts = parse_command(line)
            next if parts.nil? || parts.empty?

            break if quit_command?(parts)

            dispatch(parts)
          end
          output.puts 'Goodbye.'
        end

        private

        attr_reader :context, :input, :output

        def parse_command(line)
          command = line.strip
          return [] if command.empty?

          Shellwords.split(command)
        rescue ArgumentError => e
          output.puts "Invalid command syntax: #{e.message}"
          nil
        end

        def dispatch(parts)
          handlers = {
            'help' => -> { render_exact(parts, 'help') { render_help } },
            'hosts' => -> { render_exact(parts, 'hosts') { render_hosts } },
            'groups' => -> { render_exact(parts, 'groups') { render_groups } },
            'host' => -> { render_entity(:host, parts) },
            'group' => -> { render_entity(:group, parts) },
            'tags' => -> { render_tags(parts) },
            'audit' => -> { render_audit(parts) }
          }
          handlers.fetch(parts.first, -> { output.puts "Unknown command: #{parts.join(' ')}" }).call
        end

        def quit_command?(parts)
          parts.length == 1 && %w[quit exit].include?(parts.first)
        end

        def render_exact(parts, usage)
          return output.puts("Usage: #{usage}") unless parts.length == 1

          yield
        end

        def render_help
          output.puts 'Commands:'
          COMMANDS.each { |command| output.puts "- #{command}" }
        end

        def render_hosts
          names = context.all_hosts.map(&:name).sort
          output.puts(names.empty? ? 'No hosts.' : "Hosts: #{names.join(', ')}")
        end

        def render_groups
          names = context.all_groups.map(&:name).sort
          output.puts(names.empty? ? 'No groups.' : "Groups: #{names.join(', ')}")
        end

        def render_entity(type, parts)
          return output.puts("Usage: #{type} NAME") unless parts.length == 2

          name = parts[1]

          entity = context.public_send("find_#{type}", name)
          return output.puts("#{type.capitalize} '#{name}' not found.") if entity.nil?

          output.puts "#{type.capitalize}: #{name}"
          output.puts "Groups: #{entity.groups_dataset.map(:name).sort.join(', ')}" if type == :host
          output.puts "Hosts: #{entity.hosts_dataset.map(:name).sort.join(', ')}" if type == :group
          output.puts "Tags: #{entity.tags_dataset.map(:name).sort.join(', ')}"
        end

        def render_tags(parts)
          type = parts[1]
          name = parts[2]
          return output.puts('Usage: tags host|group NAME') unless parts.length == 3 && %w[host group].include?(type)

          entity = context.public_send("find_#{type}", name)
          return output.puts("#{type.capitalize} '#{name}' not found.") if entity.nil?

          tags = entity.tags_dataset.map(:name).sort
          output.puts tags.empty? ? "#{type.capitalize} '#{name}' has no tags." : tags.join(', ')
        end

        def render_audit(parts)
          limit = audit_limit(parts[1]) if parts.length <= 2
          return output.puts('Usage: audit [LIMIT]') if parts.length > 2 || limit.nil?

          events = context.audit_events(limit: limit)
          return output.puts('No audit events recorded.') if events.empty?

          events.each do |event|
            output.puts "#{event.id} #{event.created_at} #{event.command} #{event.entity_type}=#{event.entity_name}"
          end
        end

        def audit_limit(value)
          return 10 if value.nil?

          parsed = Integer(value)
          return parsed if parsed.positive?

          nil
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
