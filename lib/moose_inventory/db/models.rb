module Moose
  module Inventory
    module DB
      ##
      # Model for the hosts table
      class Host < Sequel::Model
        many_to_many :groups
        one_to_many :hostvars
      end

      ##
      # Model for the groups table
      class Group < Sequel::Model
        # TODO: Groups of groups? (i.e. a group with children?)
        many_to_many :hosts
        one_to_many :groupvars
      end

      ##
      # Model for the hostvars table
      class Hostvar < Sequel::Model
        many_to_one :hosts
      end

      ##
      # Model for the groupvars table
      class Groupvar < Sequel::Model
        many_to_one :groups
      end
    end
  end
end
