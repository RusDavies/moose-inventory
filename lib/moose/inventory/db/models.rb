module Moose  
  module Inventory
    module DB

      class Host < Sequel::Model
        many_to_many :groups
        one_to_many  :hostvars
        #self.raise_on_save_failure = true
      end
      
      # TODO: Groups of groups? (i.e. a group with children?)
      class Group < Sequel::Model
        many_to_many :hosts
        one_to_many  :groupvars
        #self.raise_on_save_failure = true
      end
      
      class Hostvar < Sequel::Model
        many_to_one :hosts
        #self.raise_on_save_failure = true
      end
      
      class Groupvar < Sequel::Model
        many_to_one :groups
        #self.raise_on_save_failure = true
      end
    end
  end
end
