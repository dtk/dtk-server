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
      def attributes_to_set()
        Array.new
      end

      def get_and_update_attributes(task_mh)
        #find attributes that can be updated
        #TODO: right now being conservative in including attributes that may not need to be set
        indexed_attrs_to_update = Hash.new
        (self[:component_actions]||[]).each do |action|
          (action[:attributes]||[]).each do |attr|
            if attr[:port_is_external] and attr[:port_type] == "input" and not attr[:value_asserted]
              indexed_attrs_to_update[attr[:id]] = attr
            end
          end
        end
        return nil if indexed_attrs_to_update.empty?
        search_pattern_hash = {
          :relation => :attribute,
          :filter => [:and,[:oneof, :id, indexed_attrs_to_update.keys]],
          :columns => [:id,:value_derived]
        }
        new_attr_vals = Model.get_objects_from_search_pattern_hash(task_mh.createMH(:model_name => :attribute),search_pattern_hash)
        new_attr_vals.each do |a|
          attr = indexed_attrs_to_update[a[:id]]
          #TODO: once explictly have attr[:attribute_value] need to override
          attr[:attribute_value] = attr[:value_derived] = a[:value_derived]
        end
      end

      def update_state_change_status_aux(task_mh,status,state_change_ids)
        rows = state_change_ids.map{|id|{:id => id, :status => status.to_s}}
        state_change_mh = task_mh.createMH(:model_name => :state_change)
        Model.update_from_rows(state_change_mh,rows)
      end
    end

    class CreateNode < TaskActionNode
      def initialize(state_change)
        hash = {
          :state_change_id => state_change[:id],
          :state_change_types => [state_change[:type]],
          :attributes => Array.new,
          :node => state_change[:node],
          :image => state_change[:image]
        }
        super(hash)
      end

      def add_attribute!(attr)
        self[:attributes] << attr
      end

      def attributes_to_set()
        self[:attributes].reject{|a| not a[:dynamic]} 
      end

      def ret_command_and_control_adapter_info()
        #TBD: stubbing ec2
        [:iaas,:ec2]
      end

      def save_new_node_info(task_mh)
        node = self[:node]
        hash = {
          :external_ref => node[:external_ref],
          :type => "instance"
        }
        node_idh = task_mh.createIDH(:model_name => :node, :id => node[:id])
        Model.update_from_hash_assignments(node_idh,hash)
      end

      def update_state_change_status(task_mh,status)
        update_state_change_status_aux(task_mh,status,[self[:state_change_id]])
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
          :columns => [:id,:display_name,parent_field_name,:external_ref,:attribute_value,:required,:dynamic,:port_type,:port_is_external]
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

      def update_state_change_status(task_mh,status)
        update_state_change_status_aux(task_mh,status,self[:component_actions].map{|x|x[:state_change_pointer_ids]}.flatten)
      end

     private
      def initialize(on_node_state_changes)
        sample_state_change = on_node_state_changes.first
        node = sample_state_change[:node]
        hash = {
          :node => node,
          :state_change_types => on_node_state_changes.map{|sc|sc[:type]},
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
          :on_node_config_agent_type => state_change.on_node_config_agent_type(),
        }
        self.new(hash)
      end

    end
  end
end
