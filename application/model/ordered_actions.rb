#TODO: should this be in model dircetory?
module XYZ
  class OrderedActions < Array
    def self.create(action_list)
      self.new(action_list)
    end
   private
    def initialize(action_list)
      #TODO: need to group by nodes
        #TODO stub
      if action_list.size == 1
        replace([:single_action,action_list.first])
      elsif Action.actions_are_concurrent?(action_list)
        replace([:concurrent] + action_list)
      else
        replace([:sequential] + action_list)
      end
      self
    end
  end
end
