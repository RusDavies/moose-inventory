# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      # Shared argument and warning helpers for host/group listvars commands.
      module ListvarsSupport
        private

        def validate_listvars_args(args)
          if ansible_mode?
            abort_if_wrong_ansible_listvars_arg_count(args, 1)
          else
            abort_if_missing_args(args, 1, '1 or more')
          end
        end

        def warn_if_missing_ansible_listvars_entity(entity_type, name)
          return unless ansible_mode?
          return unless missing_listvars_entity?(entity_type, name)

          fmt.warn missing_ansible_listvars_warning(entity_type, name)
        end

        def abort_if_wrong_ansible_listvars_arg_count(args, expected)
          return if args.length == expected

          abort("ERROR: Wrong number of arguments for Ansible mode, #{args.length} for #{expected}.")
        end

        def missing_listvars_entity?(entity_type, name)
          case entity_type
          when :host
            inventory_context.find_host(name).nil?
          when :group
            inventory_context.find_group(name).nil?
          else
            raise ArgumentError, "Unsupported listvars entity type: #{entity_type.inspect}"
          end
        end

        def missing_ansible_listvars_warning(entity_type, name)
          case entity_type
          when :host
            "The host #{name} does not exist.\n"
          when :group
            "The Group #{name} does not exist."
          else
            raise ArgumentError, "Unsupported listvars entity type: #{entity_type.inspect}"
          end
        end
      end
    end
  end
end
