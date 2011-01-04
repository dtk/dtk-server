#TODO: should this be in model dircetory?
module XYZ
  class OrderedActions 
    def self.create(action_list)
      self.new().set_top_level(action_list)
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

    #### 'private' methods for 'this'
    def set_top_level(action_list)
      if action_list.size == 1
        actions_by_node = group_by_node(action_list)
        return set(:single_action,actions_by_node)
      end
      actions_by_node = group_by_node(action_list)
      #TODO: stub where all actions cross-node are concurrent
      set(:concurrent,actions_by_node)
    end

   private
    def set(type,elements)
      @type = type
      @elements = elements
      self
    end
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
      NodeActions.new(action_list)
    end
  end
  class NodeActions < OrderedActions
    def initialize(action_list)
      super()
      set(:sequential,action_list)
    end

    def [](key)
      case(key)
        when :id then id()
        when :node then node()
      end
    end

    def config_agent_type
      elements.first.config_agent_type
    end
    private
    def id()
      #TODO: just taking lowest id of actions
      elements.map{|e|e[:id]}.min
    end

    def node()
      #since all nodes the same just taking first one
      elements.first[:node]
    end
  end
end
