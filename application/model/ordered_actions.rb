#TODO: in process of changing input action to state_change
module XYZ
  class OrderedActions 
    def self.create(state_change_list)
      ret = self.new().set_top_level(state_change_list)
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
    def set_top_level(state_change_list)
      if state_change_list.size == 1
        actions_by_node = group_by_node(state_change_list)
        return set(:single_action,actions_by_node)
      end
      actions_by_node = group_by_node(state_change_list)
      #TODO: stub where all actions cross-node are concurrent
      set(:concurrent,actions_by_node)
    end

    def component_actions()
      elements.map{|el|el.component_actions()}.flatten
    end

    def add_attributes!()
      cmp_actions = component_actions()
      return self if cmp_actions.empty?

      indexed_actions = cmp_actions.inject({}){|h,a|h.merge(a[:component][:id] => a)}
      parent_field_name = DB.parent_field(:component,:attribute)
      search_pattern_hash = {
        :relation => :attribute,
        :filter => [:and,
                    [:oneof, parent_field_name, indexed_actions.keys]],
        :columns => [:id,parent_field_name,:external_ref,:attribute_value,:required]
      }
      attr_mh = cmp_actions.first.model_handle().createMH(:model_name => :attribute)
      attrs = Model.get_objects_from_search_pattern_hash(attr_mh,search_pattern_hash)

      attrs.each do |attr|
        action = indexed_actions[attr[parent_field_name]]
        action.add_attribute!(attr)
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

    def group_by_node(state_change_list)
      node_ids = state_change_list.map{|a|a[:node][:id]}.uniq
      node_ids.map do |node_id| 
        NodeActions.create(state_change_list.reject{|a|not a[:node][:id] == node_id}) 
      end
    end
  end

  class NodeActions < OrderedActions
    attr_reader :create_node_state_change
    attr_accessor :node

    def self.create(state_change_list)
      create_node_state_change = state_change_list.find{|a|a[:type] == "create_node"}
      return NodeActions.new(state_change_list) unless create_node_state_change
      NodeActions.new(state_change_list.reject{|a|a[:type] == "create_node"},create_node_state_change)
    end

    def component_actions()
      elements
    end

    def save_new_node_info()
      hash = {
        :external_ref => @node[:external_ref],
        :type => "instance"
      }
      Model.update_from_hash_assignments(node_id_handle,hash)
    end

    def update_state(state)
      state_changes = all_pointed_to_state_changes()
      rows = state_changes.map{|sc|{:id => sc[:id], :state => state.to_s}}
      Model.update_from_rows(@state_change_model_handle,rows)
    end

    def [](key)
      case(key)
        when :id then id()
      end
    end

    def on_node_config_agent_type
      elements.first ? elements.first.on_node_config_agent_type : nil
    end
    def create_node_config_agent_type
      @create_node_state_change ? @create_node_state_change.create_node_config_agent_type : nil
    end
   private
    def initialize(on_node_state_changes,create_node_state_change=nil)
      super()
      @create_node_state_change = create_node_state_change
      sample_state_change = create_node_state_change || on_node_state_changes.first
      @node = sample_state_change[:node]
      @state_change_model_handle = sample_state_change.model_handle()
      @node_id_handle = @state_change_model_handle.createIDH(:id => @node[:id],:model_name => :node)

      set(:sequential,ComponentAction.order_and_group_by_component(on_node_state_changes,self))
    end

    attr_reader :node_id_handle

    def all_pointed_to_state_changes()
      (@create_node_state_change ? [@create_node_state_change] : []) + elements.map{|x|x.state_change_pointers}.flatten
    end

    def id()
      #just need arbitrary id; if there is @create_node_state_change using its id, otherwise min of  elements' ids
      @create_node_state_change ? @create_node_state_change[:id] : elements.map{|e|e[:id]}.min
    end
  end

  class ComponentAction < OrderedActions
    def self.order_and_group_by_component(state_change_list,parent)
      #TODO: stub for ordering that just takes order in which component actions reached
      component_ids = state_change_list.map{|a|a[:component][:id]}.uniq
      component_ids.map do |component_id| 
        self.new(state_change_list.reject{|a|not a[:component][:id] == component_id},parent) 
      end
    end

    def [](key)
      case(key)
        when :id then id()
        when :component then component()
        when :node then node()
        when :attributes then @attributes
      end
    end


    def add_attribute!(attr)
      @attributes << attr
    end

    attr_reader :model_handle,:on_node_config_agent_type,:state_change_pointers
   private
    attr_reader :id,:component
    def node()
      @parent.node
    end
    def initialize(state_changes_same_component,parent)
      state_change = state_changes_same_component.first
      @state_change_pointers = state_changes_same_component
      @component = state_change[:component]
      @parent = parent
      @attributes = Array.new
      @id = state_change[:id]
      @on_node_config_agent_type = state_change.on_node_config_agent_type()
      @model_handle = state_change.model_handle()
    end
  end
end
