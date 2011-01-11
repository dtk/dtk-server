module XYZ
  class TaskActionBase < HashObject 
    #implemented functions
    def to_hash()
    end
  end
  module TaskAction
    class TaskActionNode < TaskActionBase
      def update_state_aux(state,state_change_id)
        rows = state_change_ids.map{|id|{:id => id, :state => state.to_s}}
        Model.update_from_rows(self[:state_change_model_handle],rows)
      end
    end

    class CreateNode < TaskActionNode
    end

    class ConfigNode < TaskActionNode
      def self.create(state_change_list)
        ConfigNode.new(state_change_list.reject{|a|a[:type] == "create_node"})
      end

      def update_state(state)
        update_state_aux(state,component_actions.map{|x|x[:state_change_pointer_ids]}.flatten)
      end

      def on_node_config_agent_type
        component_actions.first.on_node_config_agent_type
      end
     private

      def initialize(on_node_state_changes)
        sample_state_change = on_node_state_changes.first
        node = sample_state_change[:node]
        state_change_model_handle = sample_state_change.model_handle()
        hash = {
          :node => node,
          :state_change_model_handle => state_change_model_handle,
          :node_id_handle => state_change_model_handle.createIDH(:id => :node[:id],:model_name => :node),
          :component_actions => ComponentAction.order_and_group_by_component(on_node_state_changes)
        }
        super(hash)
      end

      def id()
        #just need arbitrary id; if there is @create_node_state_change using its id, otherwise min of  elements' ids
        self[:component_actions].map{|e|e[:id]}.min
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
