# frozen_string_literal: true

module Moose
  module Inventory
    module Cli
      class Group
        desc 'addtag GROUP TAG_1 [TAG_2 ...]', 'Add metadata tags to a group'
        def addtag(*args)
          abort_if_missing_args(args, 2, '2 or more')

          add_tags('group', args[0].downcase, args.slice(1, args.length - 1))
        end

        desc 'rmtag GROUP TAG_1 [TAG_2 ...]', 'Remove metadata tags from a group'
        def rmtag(*args)
          abort_if_missing_args(args, 2, '2 or more')

          remove_tags('group', args[0].downcase, args.slice(1, args.length - 1))
        end

        desc 'listtags GROUP', 'List metadata tags for a group'
        option :format, type: :string, desc: 'Emit tags as yaml|json|pjson'
        def listtags(*args)
          abort_if_missing_args(args, 1, '1')

          list_tags('group', args[0].downcase)
        end
      end
    end
  end
end
