module XYZ
  class TaskActionBase < HashObject 
    #implemented functions
    def to_hash()
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

      def create_node_config_agent_type
        self[:config_agent_type]
      end
      def id()
        self[:state_change_id]
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

      def id()
        #just need arbitrary id; if there is @create_node_state_change using its id, otherwise min of  elements' ids
        self[:component_actions].map{|e|e[:id]}.min
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
          :component => state_change[:component],
          :attributes => Array.new,
          :id => state_change[:id],
          :on_node_config_agent_type => state_change.on_node_config_agent_type(),
          #:model_handle => state_change.model_handle()
        }
        self.new(hash)
      end
    end
  end
end
