module DTK; class Task
  class Action
    class OnNode < self
      def self.create_from_node(node)
        state_change = {:node => node}
        new(:state_change,state_change,nil)
      end
      def self.create_from_state_change(state_change,assembly_idh=nil)
        new(:state_change,state_change,nil,assembly_idh)
      end
      def self.create_from_hash(task_action_type,hash,task_idh)
        case task_action_type
          when "CreateNode"  then CreateNode.new(:hash,hash,task_idh)
          when "ConfigNode"  then ConfigNode.new(:hash,hash,task_idh)
          when "PowerOnNode" then PowerOnNode.new(:hash,hash,task_idh)
          else raise Error.new("Unexpected task_action_type (#{task_action_type})")
        end
      end
      def initialize(type,hash,task_idh=nil,assembly_idh=nil)
        unless hash[:node].kind_of?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node],task_idh.createMH(:node))
        end
        super(hash)
      end

      def node_id()
        self[:node][:id]
      end

      def attributes_to_set()
        Array.new
      end

      def get_and_propagate_dynamic_attributes(result,opts={})
        dyn_attr_val_info = get_dynamic_attributes_with_retry(result,opts)
        return if dyn_attr_val_info.empty?
        attr_mh = self[:node].model_handle_with_auth_info(:attribute)
        Attribute.update_and_propagate_dynamic_attributes(attr_mh,dyn_attr_val_info)
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(task)
        #raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(guards)
        #raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end

      def update_state_change_status_aux(task_mh,status,state_change_ids)
        rows = state_change_ids.map{|id|{:id => id, :status => status.to_s}}
        state_change_mh = task_mh.createMH(:state_change)
        Model.update_from_rows(state_change_mh,rows)
      end

     private
      def get_dynamic_attributes_with_retry(result,opts={})
        ret = get_dynamic_attributes(result)
        if non_null_attrs = opts[:non_null_attributes]
          ret = retry_get_dynamic_attributes(ret,non_null_attrs) do
            get_dynamic_attributes(result)
          end
        end
        ret
      end

      def retry_get_dynamic_attributes(dyn_attr_val_info,non_null_attrs,count=1,&block)
        if values_non_null?(dyn_attr_val_info,non_null_attrs)
          dyn_attr_val_info
        elsif count > RetryMaxCount
          raise Error.new("cannot get all attributes with keys (#{non_null_attrs.join(",")})")
        else
          sleep(RetrySleep)
          retry_get_dynamic_attributes(block.call(),non_null_attrs,count+1)
        end
      end
      RetryMaxCount = 60
      RetrySleep = 1
      def values_non_null?(dyn_attr_val_info,keys)
        keys.each do |k| 
          is_non_null = nil
          if match = dyn_attr_val_info.find{|a|a[:display_name] == k}
            if val = match[:attribute_value]
              is_non_null = (val.kind_of?(Array) ? val.find{|el|el} : true) 
            end
          end
          return nil unless is_non_null
        end
        true
      end

      #generic; can be overwritten
      def self.node_status(object,opts)
        ret = PrettyPrintHash.new
        node = object[:node]||{}
        if name = node[:display_name]
          ret[:name] = name
        end
        if id = node[:id]  
          ret[:id] = id
        end
        ret
      end
    end

    class NodeLevel < OnNode
    end

    class CreateNode < NodeLevel
      def initialize(type,hash,task_idh=nil,assembly_idh=nil)
        hash = 
          case type 
           when :state_change
            {
              :state_change_id => hash[:id],
              :state_change_types => [hash[:type]],
              :attributes => Array.new,
              :node => hash[:node]
            }
           when :hash
            hash
           else
            raise Error.new("Unexpected CreateNode.initialize type")
          end
        super
      end
      private :initialize

      def self.status(object,opts)
        ret = PrettyPrintHash.new
        ret[:node] = node_status(object,opts)
        ret
      end

      #for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:node] = (object[:node]||{})[:display_name]
        ret
      end

      def get_dynamic_attributes(result)
        ret = Array.new
        attrs_to_set = attributes_to_set()
        attr_names = attrs_to_set.map{|a|a[:display_name].to_sym}
        av_pairs__node_components = get_dynamic_attributes__node_components!(attr_names)
        rest_av_pairs = (attr_names.empty? ? {} : CommandAndControl.get_and_update_node_state!(self[:node],attr_names))
        av_pairs = av_pairs__node_components.merge(rest_av_pairs)
        return ret if av_pairs.empty?
        attrs_to_set.each do |attr|
          attr_name = attr[:display_name].to_sym
          #TODO: can test and case here whether value changes such as wehetehr new ip address
          attr[:attribute_value] = av_pairs[attr_name] if av_pairs.has_key?(attr_name)
          ret << attr
        end
        ret
      end

      ###special processing for node_components
      def get_dynamic_attributes__node_components!(attr_names)
        ret = Hash.new
        return ret unless attr_names.delete(:node_components)
        #TODO: hack
        ipv4_val = CommandAndControl.get_and_update_node_state!(self[:node],[:host_addresses_ipv4])
        return ret if ipv4_val.empty?
        cmps = self[:node].get_objs(:cols => [:components]).map{|r|r[:component][:display_name].gsub("__","::")}
        ret = {:node_components => {ipv4_val.values.first[0] => cmps}}
        if attr_names.delete(:host_addresses_ipv4)
          ret.merge!(ipv4_val)
        end
        ret
      end

      def add_attribute!(attr)
        self[:attributes] << attr
      end

      def attributes_to_set()
        self[:attributes].reject{|a| not a[:dynamic]}
      end

      def ret_command_and_control_adapter_info()
        [:iaas,R8::Config[:command_and_control][:iaas][:type].to_sym]
      end

      def update_state_change_status(task_mh,status)
        #no op if no associated state change 
        if self[:state_change_id]
          update_state_change_status_aux(task_mh,status,[self[:state_change_id]])
        end
      end

      def self.add_attributes!(attr_mh,action_list)
        ndx_actions = Hash.new
        action_list.each{|a|ndx_actions[a[:node][:id]] = a}
        return nil if ndx_actions.empty?

        parent_field_name = DB.parent_field(:node,:attribute)
        sp_hash = {
          :cols => [:id,:group_id,:display_name,parent_field_name,:external_ref,:attribute_value,:required,:dynamic],
          :filter => [:and,
                      [:eq, :dynamic, true],
                      [:oneof, parent_field_name, ndx_actions.keys]]
        }

        attrs = Model.get_objs(attr_mh,sp_hash)

        attrs.each do |attr|
          action = ndx_actions[attr[parent_field_name]]
          action.add_attribute!(attr)
        end
      end

      def create_node_config_agent_type
        self[:config_agent_type]
      end

      private
      def self.node_status(object,opts)
        node = object[:node]||{}
        ext_ref = node[:external_ref]||{}
        #TODO: want to include os type and instance id when tasks upadted with this
        kv_array = 
          [{:name => node[:display_name]},
           {:id => node[:id]},
           {:type => ext_ref[:type]},
           {:image_id => ext_ref[:image_id]},
           {:size => ext_ref[:size]},
          ]
        PrettyPrintHash.new.set?(*kv_array)
      end
    end

    ##
    # Class we are using to execute code which is responsible for handling Node
    # when she moves from pending state to running state.
    ##
    #TODO: move common fns to NodeLevel and then have this inherit to NodeLevel
    class PowerOnNode < CreateNode
    end

    class ConfigNode < OnNode
      def self.status(object,opts)
        ret = PrettyPrintHash.new
        ret[:node] = node_status(object,opts)
        unless opts[:no_components]
          ret[:components] = (object[:component_actions]||[]).map do |component_action|
            OnComponent.status(component_action,opts)
          end
        end
        ret
      end

      #for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:node] = (object[:node]||{})[:display_name]
        ret[:component_actions] = (object[:component_actions]||[]).map do |component_action|
          OnComponent.pretty_print_hash(component_action)
        end
        ret
      end

      def long_running?()
        true
      end

      def get_dynamic_attributes(result)
        ret = Array.new
        dyn_attrs = (result[:data]||{})[:dynamic_attributes]
        return ret if dyn_attrs.nil? or dyn_attrs.empty?
        dyn_attrs.map{|a|{:id => a[:attribute_id], :attribute_value => a[:attribute_val]}}
      end

      def self.add_attributes!(attr_mh,action_list)
        #ndx_actions values is an array of actions to handel case wheer component on node group and multiple nodes refernce it
        ndx_actions = Hash.new
        action_list.each do |config_node_action|
          (config_node_action[:component_actions]||[]).each do |a|
            (ndx_actions[a[:component][:id]] ||= Array.new) << a
          end
        end
        return nil if ndx_actions.empty?

        parent_field_name = DB.parent_field(:component,:attribute)
        sp_hash = {
          :relation => :attribute,
          :filter => [:oneof, parent_field_name, ndx_actions.keys],
          :columns => [:id,:display_name,parent_field_name,:external_ref,:attribute_value,:required,:dynamic,:port_type,:port_is_external, :data_type, :semantic_type, :hidden]
        }
        attrs = Model.get_objs(attr_mh,sp_hash)

        attrs.each do |attr|
          unless attr.is_constant?()
            actions = ndx_actions[attr[parent_field_name]]
            actions.each{|action|action.add_attribute!(attr)}
          end
        end
      end

      def add_internal_guards!(guards)
        self[:internal_guards] = guards
      end

      def get_and_update_attributes!(task)
        task_mh = task.model_handle()
        #these two below update the ruby obj
        get_and_update_attributes__node_ext_ref!(task_mh)
        get_and_update_attributes__cmp_attrs!(task_mh)
        get_and_update_attributes__assembly_attrs!(task_mh)
        #this updates the task model
        update_bound_input_attrs!(task)
      end

      def get_and_update_attributes__node_ext_ref!(task_mh)
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
      end

      def get_and_update_attributes__assembly_attrs!(task_mh)
        if assembly = self[:assembly_idh] &&  IDHandle.new(self[:assembly_idh]).create_object(:model_name => :assembly)
        assembly_attr_vals = assembly.get_assembly_level_attributes()
          unless assembly_attr_vals.empty?
            self[:assembly_attributes] = assembly_attr_vals
          end
        end
      end

      def get_and_update_attributes__cmp_attrs!(task_mh)
        #find attributes that can be updated
        #TODO: right now being conservative in including attributes that may not need to be set
        indexed_attrs_to_update = Hash.new
        (self[:component_actions]||[]).each do |action|
          (action[:attributes]||[]).each do |attr|
            #TODO: more efficient to just get attributes that can be inputs; right now :is_port does not
            #reflect this in cases for a3 in example a1 -external -> a2 -internal -> a3
            #so commenting out below and replacing with less stringent
            #if attr[:is_port] and not attr[:value_asserted]
            if not attr[:value_asserted]
              indexed_attrs_to_update[attr[:id]] = attr
            end
          end
        end
        return if indexed_attrs_to_update.empty?
        sp_hash = {
          :relation => :attribute,
          :filter => [:and,[:oneof, :id, indexed_attrs_to_update.keys]],
          :columns => [:id,:value_derived]
        }
        new_attr_vals = Model.get_objs(task_mh.createMH(:model_name => :attribute),sp_hash)
        new_attr_vals.each do |a|
          attr = indexed_attrs_to_update[a[:id]]
          attr[:value_derived] = a[:value_derived]
        end
      end
      def update_bound_input_attrs!(task)
        bound_input_attrs = (self[:component_actions]||[]).map do |action|
          (action[:attributes]||[]).map do |attr|
            {
              :component_display_name => action[:component][:display_name],
              :attribute_display_name => attr[:display_name],
              :attribute_value => attr[:attribute_value]
            }
          end
        end.flatten(1)
        task.update(:bound_input_attrs => bound_input_attrs)
      end

      def ret_command_and_control_adapter_info()
        [:node_config,nil]
      end

      def update_state_change_status(task_mh,status)
        update_state_change_status_aux(task_mh,status,self[:component_actions].map{|x|x[:state_change_pointer_ids]}.flatten)
      end

     private
      def initialize(type,hash,task_idh=nil,assembly_idh=nil)
         hash =
          case type
           when :state_change
            sample_state_change = hash.first
            node = sample_state_change[:node]
            h = {
              :node => node,
              :state_change_types => hash.map{|sc|sc[:type]}.uniq,
              :config_agent_type => hash.first.on_node_config_agent_type,
              :component_actions => OnComponent.order_and_group_by_component(hash)
            }
            assembly_idh ? h.merge(:assembly_idh => assembly_idh) : h
           when :hash
            if component_actions = hash[:component_actions]
              component_actions.each_with_index{|ca,i|component_actions[i] = OnComponent.create_from_hash(ca,task_idh)}
            end
            hash
           else
            raise Error.new("Unexpected ConfigNode.initialize type")
          end
        super
      end
    end
  end
end; end

