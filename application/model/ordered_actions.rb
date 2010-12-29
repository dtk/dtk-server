#TODO: should this be in model dircetory?
module XYZ
  class OrderedActions 
    def self.create(action_list)
      obj=self.new()
      obj.set_top_level(action_list)
      obj
    end
    def is_single_action?()
      @type == :single_action
    end
    def is_concurrent?()
      @type == :concurrent
    end
    def is_sequential?()
      @type == :sequential
    end
    
    def single_action()
      elements.first
    end
    def elements()
      @elements
    end

    #### 'private' methods fro 'this'
    def set_top_level(action_list)
      if action_list.size == 1
        @type = :single_action
        @elements = action_list
        return self
      end
      actions_by_node = group_by_node(action_list)
      #TODO: stub where all actions cross-node are concurrent
      @type = :concurrent
      @elements = actions_by_node
    end

   private
    attr_writer :type, :elements
    def initialize()
      @type = nil
      @elements = nil
    end

    def group_by_node(action_list)
      node_ids = action_list.map{|a|a[:node][:id]}.uniq
      node_ids.map do |node_id| 
        order_actions_in_node(action_list.reject{|a|not a[:node][:id] == node_id}) 
      end
    end

    def order_actions_in_node(action_list)
      if action_list.size == 1
        return action_list.first
      end
      #TODO: stub to determine appropriate sequential order on node
      obj = self.new()
      obj.type = :sequential
      obj.elements = action_list
      obj
    end
  end
end
