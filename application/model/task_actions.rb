module XYZ
  class TaskActionBase < HashObject 
    #implemented functions
    def serialize_for_task()
    end

    #returns [adapter_type,adapter_name], adapter name optional in which it wil be looked up from config
    def ret_command_and_control_adapter_info()
     nil
    end
  end
  module TaskAction
    module Result
      class ResultBase < HashObject
        def initialize(hash)
          super(hash)
          self[:result_type] = Aux.demodulize(self.class.to_s)
        end
      end
      class Succeeded < ResultBase
        def initialize(hash)
          super(hash)
        end
      end
      class Failed < ResultBase
        def initialize(error_class)
          #TODO: put error params in by invoking e.to_hash
          super(:error_type => Aux.demodulize(error_class.class.to_s))
        end
      end
    end
    class TaskActionNode < TaskActionBase
      def initialize(hash)
        super(hash)
        self[:attributes] = Array.new
      end
      def add_attribute!(attr)
        self[:attributes] << attr
      end

      def get_and_update_attributes(task_mh)
        #TODO: try to update if only need to
      end

      def update_state_aux(state,state_change_ids)
        rows = state_change_ids.map{|id|{:id => id, :state => state.to_s}}
        Model.update_from_rows(self[:state_change_model_handle],rows)
      end
    end

    class CreateNode < TaskActionNode
      def self.create(state_change_list)
        create_node_state_change = state_change_list.find{|a|a[:type] == "create_node"}
        create_node_state_change ? CreateNode.new(create_node_state_change) : nil
      end

      def ret_command_and_control_adapter_info()
        #TBD: stubbing ec2
        [:iaas,:ec2]
      end

      def save_new_node_info()
        hash = {
          :external_ref => self[:node][:external_ref],
          :type => "instance"
        }
        Model.update_from_hash_assignments(self[:node_id_handle],hash)
      end

      def update_state(state)
        update_state_aux(state,[self[:state_change_id]])
      end

      def self.add_attributes!(attr_mh,action_list)
        indexed_actions = Hash.new
        action_list.each{|a|indexed_actions[a[:node][:id]] = a}
        return nil if indexed_actions.empty?

        node_ids = action_list.map{|x|x[:node][:id]}
        parent_field_name = DB.parent_field(:node,:attribute)
        search_pattern_hash = {
          :relation => :attribute,
          :filter => [:and,
                      [:eq, :dynamic, true],
                      [:oneof, parent_field_name, indexed_actions.keys]],
          :columns => [:id,:display_name,parent_field_name,:external_ref,:attribute_value,:required,:dynamic]
        }

        attrs = Model.get_objects_from_search_pattern_hash(attr_mh,search_pattern_hash)

        attrs.each do |attr|
          action = indexed_actions[attr[parent_field_name]]
          action.add_attribute!(attr)
        end
      end


      def create_node_config_agent_type
        self[:config_agent_type]
      end

     private
      def initialize(state_change)
        node = state_change[:node]
        state_change_model_handle = state_change.model_handle()
        hash = {
          :state_change_id => state_change[:id],
          :state_change_model_handle => state_change.model_handle(),
          :node => state_change[:node],
          :node_id_handle => state_change_model_handle.createIDH(:id => node[:id],:model_name => :node),
          :image => state_change[:image]
        }
        super(hash)
      end
    end

    class ConfigNode < TaskActionNode
      def self.add_attributes!(attr_mh,action_list)
        indexed_actions = Hash.new
        action_list.each do |config_node_action|
          (config_node_action[:component_actions]||[]).each{|a|indexed_actions[a[:component][:id]] = a}
        end
        return nil if indexed_actions.empty?

        parent_field_name = DB.parent_field(:component,:attribute)
        search_pattern_hash = {
          :relation => :attribute,
          :filter => [:and,
                      [:oneof, parent_field_name, indexed_actions.keys]],
          :columns => [:id,:display_name,parent_field_name,:external_ref,:attribute_value,:required,:dynamic]
      }
        attrs = Model.get_objects_from_search_pattern_hash(attr_mh,search_pattern_hash)

        attrs.each do |attr|
          action = indexed_actions[attr[parent_field_name]]
          action.add_attribute!(attr)
        end
      end

      def get_and_update_attributes(task_mh)
        #TODO: may treat updating node as regular attribute
        #no up if already have the node's external ref
        unless ((self[:node]||{})[:external_ref]||{})[:instance_id]
          node_id = (self[:node]||{})[:id]
          if node_id
            node_info = Model.get_object_columns(task_mh.createIDH(:id => node_id, :model_name => :node),[:external_ref])
            self[:node][:external_ref] = node_info[:external_ref]
          else
            Log.error("cannot update task action's node id because do not have its id")
          end
        end
        super(task_mh)
      end

      def ret_command_and_control_adapter_info()
        #TBD: stub
        [:node_config,nil]
      end

      def self.create(state_change_list)
        on_node_state_changes = state_change_list.reject{|a|a[:type] == "create_node"}
        on_node_state_changes.empty? ? nil :  ConfigNode.new(on_node_state_changes) 
      end

      def update_state(state)
        update_state_aux(state,self[:component_actions].map{|x|x[:state_change_pointer_ids]}.flatten)
      end

     private
      def initialize(on_node_state_changes)
        sample_state_change = on_node_state_changes.first
        node = sample_state_change[:node]
        state_change_model_handle = sample_state_change.model_handle()
        hash = {
          :node => node,
          :state_change_model_handle => state_change_model_handle,
          :config_agent_type => on_node_state_changes.first.on_node_config_agent_type,
          :component_actions => ComponentAction.order_and_group_by_component(on_node_state_changes)
        }
        super(hash)
      end
    end


    class ComponentAction < HashObject
      def self.order_and_group_by_component(state_change_list)
        #TODO: stub for ordering that just takes order in which component state changes made
        component_ids = state_change_list.map{|a|a[:component][:id]}.uniq
        component_ids.map do |component_id| 
          self.create(state_change_list.reject{|a|not a[:component][:id] == component_id}) 
        end
      end

      def add_attribute!(attr)
        self[:attributes] << attr
      end

      private
      def self.create(state_changes_same_component)
        state_change = state_changes_same_component.first
        hash = {
          :state_change_pointer_ids => (state_changes_same_component||[]).map{|sc|sc[:id]},
          :attributes => Array.new,
          :component => state_change[:component],
          :id => state_change[:id],
          :on_node_config_agent_type => state_change.on_node_config_agent_type(),
        }
        self.new(hash)
      end

    end
  end
end
