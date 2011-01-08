#TODO: should this be in model dircetory?
module XYZ
  class OrderedActions 
    def self.create(action_list)
      ret = self.new().set_top_level(action_list)
      ret.add_attributes!()
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

    def node_config_actions()
      elements.map{|el|el.node_config_actions()}.flatten
    end

    def add_attributes!()
      actions = node_config_actions()
      return self if actions.empty?

      indexed_actions = actions.inject({}){|h,a|h.merge(a[:component][:id] => a)}
      parent_field_name = DB.parent_field(:component,:attribute)
      search_pattern_hash = {
        :relation => :attribute,
        :filter => [:and,
                    [:oneof, parent_field_name, indexed_actions.keys]],
        :columns => [:id,parent_field_name,:external_ref,:attribute_value,:required]
      }
      attr_mh = actions.first.model_handle().createMH(:model_name => :attribute)
      attrs = Model.get_objects_from_search_pattern_hash(attr_mh,search_pattern_hash)

      attrs.each do |attr|
        action = indexed_actions[attr[parent_field_name]]
        action[:attributes] ||= Array.new
        action[:attributes] << attr
      end
      self
    end

   private
    def set(type,elements)
      @type = type
      @elements = elements
      self
    end
    def initialize()
      @type = nil
      @elements = Array.new
    end

    def group_by_node(action_list)
      node_ids = action_list.map{|a|a[:node][:id]}.uniq
      node_ids.map do |node_id| 
        NodeActions.create(action_list.reject{|a|not a[:node][:id] == node_id}) 
      end
    end
  end

  class NodeActions < OrderedActions
    attr_reader :create_node_action
    attr_accessor :node
    def node_config_actions()
      elements.map{|el|el.action}.compact
    end

    def self.create(action_list)
      #shortcut if singleton
      return NodeActions.new(action_list) if action_list.size == 1
      create_node_action = action_list.find{|a|a[:type] == "create_node"}
      return NodeActions.new(action_list) unless create_node_action
      NodeActions.new(action_list.reject{|a|a[:type] == "create_node"},create_node_action)
    end

    #TODO: may deprecate after removing refs
    def [](key)
      case(key)
        when :id then id()
      end
    end

    def on_node_config_agent_type
      elements.first.action.on_node_config_agent_type
    end
    def create_node_config_agent_type
      @create_node_action ? @create_node_action.create_node_config_agent_type : nil
    end
   private
    def initialize(on_node_actions,create_node_action=nil)
      super()
      @create_node_action = create_node_action
      @node = (create_node_action or on_node_actions.empty?) ? nil : on_node_actions.first[:node]
      set(:sequential,ComponentAction.order_and_group_by_component(on_node_actions))
    end

    def id()
      #TODO: just taking lowest id of actions
      elements.map{|e|e.action[:id]}.min
    end
  end

  class ComponentAction < OrderedActions
    def self.order_and_group_by_component(action_list)
      #TODO: stub for ordering that just takes order in which component actions reached
      component_ids = action_list.map{|a|a[:component][:id]}.uniq
      component_ids.map do |component_id| 
        self.new(action_list.reject{|a|not a[:component][:id] == component_id}) 
      end
    end
    attr_reader :action
   private
    def initialize(actions_same_component)
      @action_pointers = actions_same_component
      #all actions will be teh same from perpective of any operation (i.e., will have component id and all its attributes 
      @action = actions_same_component.first
    end
  end
end
