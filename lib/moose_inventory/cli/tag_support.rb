# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared host/group metadata tag commands.
      module TagSupport
        private

        def add_tags(entity_type, entity_name, tag_names)
          entity = fetch_tag_entity(entity_type, entity_name)
          normalized = normalize_tags(tag_names)
          changed = []

          db.transaction do
            normalized.each do |tag_name|
              tag = db.models[:tag].find_or_create(name: tag_name)
              next unless entity.tags_dataset[name: tag_name].nil?

              entity.add_tag(tag)
              changed << tag_name
            end
          end

          result = tag_result(events: changed.map { |tag| tag_event(:tag_added, entity_type, entity_name, tag) })
          record_tag_audit(command: 'addtag', action: 'add_tag', entity_type: entity_type,
                           entity_name: entity_name, result: result, changed: changed)
          puts "Added #{entity_type} tag(s) to '#{entity_name}': #{changed.join(', ')}."
        end

        def remove_tags(entity_type, entity_name, tag_names)
          entity = fetch_tag_entity(entity_type, entity_name)
          normalized = normalize_tags(tag_names)
          changed = []

          db.transaction do
            normalized.each do |tag_name|
              tag = entity.tags_dataset[name: tag_name]
              next if tag.nil?

              entity.remove_tag(tag)
              changed << tag_name
            end
          end

          result = tag_result(events: changed.map { |tag| tag_event(:tag_removed, entity_type, entity_name, tag) })
          record_tag_audit(command: 'rmtag', action: 'remove_tag', entity_type: entity_type,
                           entity_name: entity_name, result: result, changed: changed)
          puts "Removed #{entity_type} tag(s) from '#{entity_name}': #{changed.join(', ')}."
        end

        def list_tags(entity_type, entity_name)
          entity = fetch_tag_entity(entity_type, entity_name)
          tags = entity.tags_dataset.order(:name).map(:name)

          if options[:format]
            fmt.dump({ entity_type => entity_name, tags: tags }, options[:format].downcase)
          elsif tags.empty?
            puts "#{entity_type.capitalize} '#{entity_name}' has no tags."
          else
            puts "#{entity_type.capitalize} '#{entity_name}' tags: #{tags.join(', ')}"
          end
        end

        def fetch_tag_entity(entity_type, entity_name)
          entity = inventory_context.public_send("find_#{entity_type}", entity_name)
          abort("ERROR: The #{entity_type} '#{entity_name}' does not exist.") if entity.nil?

          entity
        end

        def normalize_tags(values)
          values.map { |value| value.to_s.downcase.strip }.reject(&:empty?).uniq
        end

        def tag_result(events:)
          Moose::Inventory::Operations::OperationEventSupport::Result.new(events: events, warning_count: 0)
        end

        def tag_event(type, entity_type, entity_name, tag_name)
          Moose::Inventory::Operations::OperationEventSupport::Event.new(
            type: type,
            payload: { entity_type: entity_type, entity_name: entity_name, tag: tag_name }
          )
        end

        def record_tag_audit(metadata)
          return if metadata.fetch(:changed).empty?

          record_audit({ command: "#{metadata.fetch(:entity_type)} #{metadata.fetch(:command)}",
                         action: metadata.fetch(:action), entity_type: metadata.fetch(:entity_type),
                         entity_names: metadata.fetch(:entity_name) }, result: metadata.fetch(:result))
        end
      end
    end
  end
end
