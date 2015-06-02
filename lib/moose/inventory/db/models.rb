module Moose
  module Inventory
    module DB

      class Host < Sequel::Model
        many_to_many :groups
        one_to_many :hostvars
      end

      # TODO: Groups of groups? (i.e. a group with children?)
      class Group < Sequel::Model
        many_to_many :hosts
        one_to_many :groupvars
      end

      class Hostvar < Sequel::Model
        many_to_one :hosts
      end

      class Groupvar < Sequel::Model
        many_to_one :groups
      end
    end
  end
end
