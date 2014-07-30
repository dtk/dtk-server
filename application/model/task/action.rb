module DTK; class Task
  class Action < HashObject 
    def type()
      Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
    end

    # implemented functions
    def long_running?()
      nil
    end

    # returns [adapter_type,adapter_name], adapter name optional in which it wil be looked up from config
    def ret_command_and_control_adapter_info()
     nil
    end

    class OnNode < self
      def self.create_from_node(node)
        state_change = {:node => node}
        new(:state_change,state_change,nil)
      end
      def self.create_from_state_change(state_change,assembly_idh=nil)
        new(:state_change,state_change,nil,assembly_idh)
      end
      def self.create_from_hash(task_action_type,hash,task_idh=nil)
        case task_action_type
          when "CreateNode"  then CreateNode.new(:hash,hash,task_idh)
          when "ConfigNode"  then ConfigNode.new(:hash,hash,task_idh)
          when "PowerOnNode" then PowerOnNode.new(:hash,hash,task_idh)
          when "InstallAgent" then InstallAgent.new(:hash,hash,task_idh)
          when "ExecuteSmoketest" then ExecuteSmoketest.new(:hash,hash,task_idh)
          when "Hash" then InstallAgent.new(:hash,hash,task_idh) #RICH-WF; Aldin compensating form bug in task creation
          else raise Error.new("Unexpected task_action_type (#{task_action_type})")
        end
      end

      def task_action_type()
        @task_action_type ||= self.class.to_s.split('::').last
      end

      def initialize(type,hash,task_idh=nil)
        unless hash[:node].kind_of?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node],task_idh.createMH(:node),:subclass=>true)
        end
        super(hash)
      end


      ###====== related to node(s); node can be a node group
      def nodes()
        if self[:node].is_node_group?()
          self[:node].get_node_members()
        else
          [self[:node]]
        end
      end

      def node_id()
        self[:node][:id]
      end

      def get_and_propagate_dynamic_attributes(result,opts={})
        dyn_attr_val_info = get_dynamic_attributes_with_retry(result,opts)
        return if dyn_attr_val_info.empty?
        attr_mh = self[:node].model_handle_with_auth_info(:attribute)
        Attribute.update_and_propagate_dynamic_attributes(attr_mh,dyn_attr_val_info)
      end

      ###====== end: related to node(s); node can be a node group

      def attributes_to_set()
        Array.new
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end

      def update_state_change_status_aux(task_mh,status,state_change_ids)
        rows = state_change_ids.map{|id|{:id => id, :status => status.to_s}}
        state_change_mh = task_mh.createMH(:state_change)
        Model.update_from_rows(state_change_mh,rows)
      end

     private
      def node_create_obj_optional_subclass(node)
        node && node.create_obj_optional_subclass()
      end

      def get_dynamic_attributes_with_retry(result,opts={})
        ret = get_dynamic_attributes(result)
        if non_null_attrs = opts[:non_null_attributes]
          ret = retry_get_dynamic_attributes(ret,non_null_attrs){get_dynamic_attributes(result)}
        end
        ret
      end

      def retry_get_dynamic_attributes(dyn_attr_val_info,non_null_attrs,count=1,&block)
        if values_non_null?(dyn_attr_val_info,non_null_attrs)
          dyn_attr_val_info
        elsif count > RetryMaxCount
          raise Error.new("cannot get all attributes with keys (#{non_null_attrs.join(",")})")
        elsif block.nil?
          raise Error.new("Unexpected that block.nil?")
        else
          sleep(RetrySleep)
          retry_get_dynamic_attributes(block.call(),non_null_attrs,count+1,&block)
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

      # generic; can be overwritten
      def self.node_status(object,opts)
        ret = PrettyPrintHash.new
        node = object[:node]||{}
        if name = node_status__name(node)
          ret[:name] = name
        end
        if id = node[:id]  
          ret[:id] = id
        end
        ret
      end

      def self.node_status__name(node)
        node && Node.assembly_node_print_form?(node)
      end

    end

    class NodeLevel < OnNode
    end

    class PhysicalNode < self
      def initialize(type,hash,task_idh=nil)
        unless hash[:node].kind_of?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node],task_idh.createMH(:node),:subclass=>true)
        end
        super(hash)
      end

      def self.create_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          :node => node,
          :datacenter => target,
          :user_object => CurrentSession.new.get_user_object()
        }

        InstallAgent.new(:hash,hash)
      end

      def self.create_smoketest_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          :node => node,
          :datacenter => target,
          :user_object => CurrentSession.new.get_user_object()
        }

        ExecuteSmoketest.new(:hash,hash)
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end
    end


    r8_nested_require('action','create_node')
    r8_nested_require('action','config_node')
    r8_nested_require('action','on_component')
    r8_nested_require('action','install_agent')
    r8_nested_require('action','execute_smoketest')

    class Result < HashObject
      def initialize(hash={})
        super(hash)
        self[:result_type] = Aux.demodulize(self.class.to_s).downcase
      end

      class Succeeded < self
        def initialize(hash={})
          super(hash)
        end
      end
      class Failed < self
        def initialize(error)
          super()
          self[:error] =  error.to_hash
        end
      end
      class Cancelled < self
        def initialize(hash={})
          super(hash)
        end
      end
    end
  end
end; end
