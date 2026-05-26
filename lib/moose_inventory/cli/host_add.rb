require 'thor'
require 'json'
require 'indentation'

require_relative './formatter.rb'
require_relative '../db/exceptions.rb'
require_relative '../operations/add_hosts.rb'

module Moose
  module Inventory
    module Cli
      ##
      # Class implementing the "host" methods of the CLI
      class Host
        #==========================
        desc 'add HOSTNAME_1 [HOSTNAME_2 ...]',
             'Add a hosts HOSTNAME_n to the inventory'
        option :groups
        # rubocop:disable Metrics/LineLength
        def add(*argv) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          # rubocop:enable Metrics/LineLength
          abort_if_missing_args(argv, 1, '1 or more')

          # Arguments
          names = normalize_names(argv)

          # split(/\W+/) splits on hyphens too, which is not what we want
          # groups = options[:groups].downcase.split(/\W+/).uniq
          groups = csv_option_names(options[:groups])

          # Sanity
          abort_if_automatic_group(groups)

          Moose::Inventory::Operations::AddHosts
            .new(db: db, formatter: fmt)
            .call(names: names, groups: groups)
          puts 'Succeeded'
        end
      end
    end
  end
end
