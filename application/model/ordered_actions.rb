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
      #shortcut if singleton
      return NodeActions.new(action_list) if action_list.size == 1
      #TODO: stub that just uses order given aside from a create a node which goes before all otehr node operations
      create_node_action = action_list.find{|a|a[:type] == "create_node"}
      return NodeActions.new(action_list) unless create_node_action
      NodeActions.new(action_list.reject{|a|a[:type] == "create_node"},create_node_action)
    end
  end
  class NodeActions < OrderedActions
    def initialize(on_node_actions,create_node_action=nil)
      super()
      @create_node_action = create_node_action
      @node = (create_node_action or on_node_actions.empty?) ? nil : on_node_actions.first[:node]
      set(:sequential,on_node_actions)
    end

    def [](key)
      case(key)
        when :id then id()
        when :node then @node
      end
    end

    def on_node_config_agent_type
      elements.first.on_node_config_agent_type
    end
    def create_node_config_agent_type
      @create_node_action ? @create_node_action.create_node_config_agent_type : nil
    end
   private
    def id()
      #TODO: just taking lowest id of actions
      elements.map{|e|e[:id]}.min
    end
  end
end
