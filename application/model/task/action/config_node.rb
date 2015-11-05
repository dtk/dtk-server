module DTK; class Task
  class Action
    class ConfigNode < OnNode
      def self.create_from_execution_blocks(exec_blocks, assembly_idh = nil)
        task_idh = nil #not needed in new
        new(:execution_blocks, exec_blocks, task_idh, assembly_idh)
      end

      def create_node_group_member(node)
        self.class.new(:hash, node: node, node_group_member: true)
      end

      def self.component_actions(obj)
        obj[:component_actions] || []
      end
      def component_actions
        self.class.component_actions(self)
      end

      def set_intra_node_stages!(intra_node_stages)
        self[:intra_node_stages] = intra_node_stages
      end

      def intra_node_stages
        self[:intra_node_stages]
      end

      def set_inter_node_stage!(internode_stage_index)
        self[:inter_node_stage] = internode_stage_index && internode_stage_index.to_s
      end

      def inter_node_stage
        self[:inter_node_stage]
      end

      def is_first_inter_node_stage?
        inter_node_stage = inter_node_stage()
        inter_node_stage.nil? || inter_node_stage == '1'
      end

      def self.status(object, opts)
        ret = PrettyPrintHash.new
        ret[:node] = node_status(object, opts)
        unless opts[:no_components]
          ret[:components] = component_actions(object).map do |component_action|
            OnComponent.status(component_action, opts)
          end
        end
        ret
      end

      # for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:node] = (object[:node] || {})[:display_name]
        ret[:component_actions] = component_actions(object).map do |component_action|
          OnComponent.pretty_print_hash(component_action)
        end
        ret
      end

      def long_running?
        true
      end

      def get_dynamic_attributes(result)
        ret = []
        dyn_attrs = (result[:data] || {})[:dynamic_attributes]
        return ret if dyn_attrs.nil? || dyn_attrs.empty?
        dyn_attrs.map { |a| { id: a[:attribute_id], attribute_value: sanitize_attribute_val(a[:attribute_val]) } }
      end

      def sanitize_attribute_val(val)
        if val.is_a?(Symbol)
          val.to_s
        else
          val
        end
      end

      def self.add_attributes!(attr_mh, action_list)
        # ndx_actions values is an array of actions to handel case wheer component on node group and multiple nodes refernce it
        ndx_actions = {}
        action_list.each do |config_node_action|
          component_actions(config_node_action).each do |a|
            (ndx_actions[a[:component][:id]] ||= []) << a
          end
        end
        return nil if ndx_actions.empty?

        parent_field_name = DB.parent_field(:component, :attribute)
        sp_hash = {
          relation: :attribute,
          filter: [:oneof, parent_field_name, ndx_actions.keys],
          columns: [:id, :display_name, parent_field_name, :external_ref, :attribute_value, :required, :dynamic, :port_type, :port_is_external, :data_type, :semantic_type, :hidden]
        }
        attrs = Model.get_objs(attr_mh, sp_hash)

        attrs.each do |attr|
          unless attr.is_constant?()
            actions = ndx_actions[attr[parent_field_name]]
            actions.each { |action| action.add_attribute!(attr) }
          end
        end
      end

      def add_internal_guards!(guards)
        self[:internal_guards] = guards
      end

      def get_and_update_attributes!(task)
        task_mh = task.model_handle()
        # these two below update the ruby obj
        get_and_update_attributes__node_ext_ref!(task_mh)
        get_and_update_attributes__cmp_attrs!(task_mh)
        get_and_update_attributes__assembly_attrs!(task_mh)
        # this updates the task model
        update_bound_input_attrs!(task)
      end

      def get_and_update_attributes__node_ext_ref!(task_mh)
        # TODO: may treat updating node as regular attribute
        # no up if already have the node's external ref
        unless ((self[:node] || {})[:external_ref] || {})[:instance_id]
          node_id = (self[:node] || {})[:id]
          if node_id
            node_info = Model.get_object_columns(task_mh.createIDH(id: node_id, model_name: :node), [:external_ref])
            self[:node][:external_ref] = node_info[:external_ref]
          else
            Log.error("cannot update task action's node id because do not have its id")
          end
        end
      end

      def get_and_update_attributes__assembly_attrs!(_task_mh)
        if assembly = self[:assembly_idh] && IDHandle.new(self[:assembly_idh]).create_object(model_name: :assembly)
        assembly_attr_vals = assembly.get_assembly_level_attributes()
          unless assembly_attr_vals.empty?
            self[:assembly_attributes] = assembly_attr_vals
          end
        end
      end

      def get_and_update_attributes__cmp_attrs!(task_mh)
        # find attributes that can be updated
        # TODO: right now being conservative in including attributes that may not need to be set
        indexed_attrs_to_update = {}
        component_actions().each do |action|
          (action[:attributes] || []).each do |attr|
            # TODO: more efficient to just get attributes that can be inputs; right now :is_port does not
            # reflect this in cases for a3 in example a1 -external -> a2 -internal -> a3
            # so commenting out below and replacing with less stringent
            # if attr[:is_port] and not attr[:value_asserted]
            unless attr[:value_asserted]
              indexed_attrs_to_update[attr[:id]] = attr
            end
          end
        end
        return if indexed_attrs_to_update.empty?
        sp_hash = {
          relation: :attribute,
          filter: [:and, [:oneof, :id, indexed_attrs_to_update.keys]],
          columns: [:id, :value_derived]
        }
        new_attr_vals = Model.get_objs(task_mh.createMH(model_name: :attribute), sp_hash)
        new_attr_vals.each do |a|
          attr = indexed_attrs_to_update[a[:id]]
          attr[:value_derived] = a[:value_derived]
        end
      end

      def update_bound_input_attrs!(task)
        bound_input_attrs = component_actions().flat_map do |action|
          (action[:attributes] || []).map do |attr|
            {
              component_display_name: action[:component][:display_name],
              attribute_display_name: attr[:display_name],
              attribute_value: attr[:attribute_value]
            }
          end
        end
        task.update(bound_input_attrs: bound_input_attrs)
      end

      def execute_on_server?
        ConfigAgent::Type.is_a?(config_agent_type, [:ruby_function, :no_op])
      end

      def action_agent_call?
        ConfigAgent::Type.is_a?(config_agent_type, [:dtk_provider])
      end

      # returns [adapter_type, adapter_name]
      # adapter_name can be nil meaning default adapter should be used
      def ret_command_and_control_adapter_info
        adapter_type = :node_config
        adapter_name = :server if execute_on_server?
        adapter_name = :stomp  if action_agent_call?
        [adapter_type, adapter_name]
      end

      def update_state_change_status(task_mh, status)
        update_state_change_status_aux(task_mh, status, component_actions().map { |a| a[:state_change_pointer_ids] }.compact.flatten)
      end

      def config_agent_type
        self[:config_agent_type] || fail(Error.new('self[:config_agent_type] should not be nil'))
      end

      # TODO: hard wired that if there is a action_method?, there is just one
      def action_method?
        matches = component_actions.map do |a|
          if action_method = a.kind_of?(OnComponent) && a.action_method?
            action_method
          end
        end.compact
        if matches.size == 0
          nil
        elsif matches.size == 1
          matches.first
        else
          Log.error_pp(['Unexpected that multiple actions found on exacutable action' , self])
          nil
        end
      end

      private

      def initialize(type, object, task_idh = nil, assembly_idh = nil)
        # TODO: clean up so dont have to look for assembly_idh in two places
        assembly_idh ||= object[:assembly_idh]
        intra_node_stages = hash = nil
        case type
          when :state_change
            sc = object
            sample_state_change = sc.first
            node = sample_state_change[:node]
            component_actions, intra_node_stages = OnComponent.order_and_group_by_component(sc)
            hash = {
              node: node,
              state_change_types: sc.map { |sc| sc[:type] }.uniq,
              config_agent_type: sc.first.on_node_config_agent_type,
              component_actions: component_actions
            }
            hash.merge!(assembly_idh: assembly_idh) if assembly_idh
          when :hash
            if component_actions = object[:component_actions]
              component_actions.each_with_index { |ca, i| component_actions[i] = OnComponent.create_from_hash(ca, task_idh) }
            end
            hash = object
          when :execution_blocks
            exec_blocks = object
            actions, config_agent_type = OnComponent.create_actions_from_execution_blocks(exec_blocks)
            hash = {
              node: exec_blocks.node(),
              state_change_types: ['converge_component'],
              config_agent_type: config_agent_type,
              component_actions: actions
            }
            hash.merge!(assembly_idh: assembly_idh) if assembly_idh
            intra_node_stages = exec_blocks.intra_node_stages()
          else
            fail Error.new('Unexpected ConfigNode.initialize type')
          end
        super(type, hash, task_idh)
        # set_intra_node_stages must be done after super
        set_intra_node_stages!(intra_node_stages) if intra_node_stages
      end
    end
  end
end; end
