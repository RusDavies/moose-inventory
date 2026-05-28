# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Small read-only interactive console for browsing inventory state.
      class Console
        COMMANDS = [
          'help',
          'hosts',
          'groups',
          'host NAME',
          'group NAME',
          'tags host NAME',
          'tags group NAME',
          'audit [LIMIT]',
          'quit'
        ].freeze

        def initialize(context:, input: $stdin, output: $stdout)
          @context = context
          @input = input
          @output = output
        end

        def run
          output.puts 'Moose Inventory console (read-only). Type help or quit.'
          input.each_line do |line|
            command = line.strip
            next if command.empty?

            break if quit_command?(command)

            dispatch(command.split)
          end
          output.puts 'Goodbye.'
        end

        private

        attr_reader :context, :input, :output

        def dispatch(parts)
          handlers = {
            'help' => -> { render_help },
            'hosts' => -> { render_hosts },
            'groups' => -> { render_groups },
            'host' => -> { render_entity(:host, parts[1]) },
            'group' => -> { render_entity(:group, parts[1]) },
            'tags' => -> { render_tags(parts[1], parts[2]) },
            'audit' => -> { render_audit(parts[1]) }
          }
          handlers.fetch(parts.first, -> { output.puts "Unknown command: #{parts.join(' ')}" }).call
        end

        def quit_command?(command)
          %w[quit exit].include?(command)
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

        def render_entity(type, name)
          return output.puts("Usage: #{type} NAME") if name.nil?

          entity = context.public_send("find_#{type}", name)
          return output.puts("#{type.capitalize} '#{name}' not found.") if entity.nil?

          output.puts "#{type.capitalize}: #{name}"
          output.puts "Groups: #{entity.groups_dataset.map(:name).sort.join(', ')}" if type == :host
          output.puts "Hosts: #{entity.hosts_dataset.map(:name).sort.join(', ')}" if type == :group
          output.puts "Tags: #{entity.tags_dataset.map(:name).sort.join(', ')}"
        end

        def render_tags(type, name)
          return output.puts('Usage: tags host|group NAME') unless %w[host group].include?(type) && !name.nil?

          entity = context.public_send("find_#{type}", name)
          return output.puts("#{type.capitalize} '#{name}' not found.") if entity.nil?

          tags = entity.tags_dataset.map(:name).sort
          output.puts tags.empty? ? "#{type.capitalize} '#{name}' has no tags." : tags.join(', ')
        end

        def render_audit(limit)
          events = context.audit_events(limit: audit_limit(limit))
          return output.puts('No audit events recorded.') if events.empty?

          events.each do |event|
            output.puts "#{event.id} #{event.created_at} #{event.command} #{event.entity_type}=#{event.entity_name}"
          end
        end

        def audit_limit(value)
          return 10 if value.nil?

          Integer(value)
        rescue ArgumentError
          10
        end
      end
    end
  end
end
