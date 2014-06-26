module DTK
  module CommandAndControlAdapter
  end
  class CommandAndControl
    r8_nested_require('command_and_control','install_script')

    def initialize(task,top_task_idh)
      @task_idh =  task.id_handle()
      @top_task_idh = top_task_idh
      @task_action = task[:executable_action]
      @klass = self.class.load_for(@task_action)
    end
    attr_reader :task_idh,:top_task_idh,:task_action,:klass

    def self.execute_task_action(task,top_task_idh)
      new(task,top_task_idh).execute().merge(:task_id => task.id())
    end
    def execute()
      klass.execute(task_idh,top_task_idh,task_action)
    end

    def self.initiate_task_action(task,top_task_idh,opts={})
      new(task,top_task_idh).initiate(opts)
    end
    def initiate(opts={})
      if opts[:cancel_task]
        klass.initiate_cancelation(task_idh,top_task_idh,task_action,opts)   
      elsif opts[:sync_agent_task]
        klass.initiate_sync_agent_code(task_idh,top_task_idh,task_action,opts)         
      else
        klass.initiate_execution(task_idh,top_task_idh,task_action,opts)
      end
    end

    def self.install_script(node)
      InstallScript.install_script(node)
    end

    def self.discover(filter, timeout, limit, client)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.discover(filter, timeout, limit, client)
    end

    def self.get_mcollective_client()
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.get_mcollective_client()
    end

    # This takes into account what is needed for the node_config_adapter
    def self.node_config_adapter_install_script(node,bindings)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.install_script(node,bindings)
    end

    def self.pbuilderid(node)
      klass = load_iaas_for(:node => node)
      klass.pbuilderid(node)
    end

    def self.existing_image?(image_id,image_type)
      klass = load_iaas_for(:image_type => image_type)
      klass.existing_image?(image_id)
    end

    def self.references_image?(target,node_external_ref)
      klass = load_iaas_for(:target => target)
      klass.references_image?(node_external_ref)
    end

    def self.start_instances(nodes)
      klass = load_iaas_for(:node => nodes.first)
      klass.start_instances(nodes)
    end

    def self.stop_instances(nodes)
      klass = load_iaas_for(:node => nodes.first)
      klass.stop_instances(nodes)
    end

    def self.check_and_process_iaas_properties(iaas_type, iaas_properties)
      klass = load_for_aux(:iaas, iaas_type.to_s)
      klass.check_iaas_properties(iaas_properties)
    end

    def self.find_matching_node_binding_rule(node_binding_rules,target)
      target.update_object!(:iaas_type,:iaas_properties)
      klass = load_iaas_for(:target => target)
      klass.find_matching_node_binding_rule(node_binding_rules,target)
    end

    def self.node_config_server_host()
      klass = load_config_node_adapter()
      klass.server_host()
    end

    def self.destroy_node?(node,opts={})
      klass = load_iaas_for(:node => node)
      klass.destroy_node?(node,opts)
    end

    def self.associate_persistent_dns?(node)
      klass = load_iaas_for(:node => node)
      klass.associate_persistent_dns?(node)
    end

    def self.associate_elastic_ip(node)
      klass = load_iaas_for(:node => node)
      klass.associate_elastic_ip(node)
    end

    def self.get_and_update_node_state!(node,attribute_names)
      # TODO: Haris - Test more this change
      adapter_name = node.get_target_iaas_type() || R8::Config[:command_and_control][:iaas][:type]
      klass = load_for_aux(:iaas,adapter_name)      
      klass.get_and_update_node_state!(node,attribute_names)
    end

    def self.get_node_operational_status(node)
      adapter_name = R8::Config[:command_and_control][:iaas][:type]
      klass = load_for_aux(:iaas,adapter_name)      
      klass.get_node_operational_status(node)
    end

    def self.request__get_logs(task,nodes,callbacks,context)
      klass = load_for(task)
      klass.request__get_logs(task,nodes,callbacks,context)
    end

    def self.parse_response__get_logs(task,msg)
      klass = load_for(task)
      klass.parse_response__get_logs(msg)
    end

    def self.request__execute_action(agent,action,nodes,callbacks,params={})
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.request__execute_action(agent,action,nodes,callbacks,params)
    end

    def self.request__execute_action_per_node(agent,action,nodes_hash,callbacks)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.request_execute_action_per_node(agent,action,nodes_hash,callbacks)
    end
    
    def self.parse_response__execute_action(nodes,msg)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.parse_response__execute_action(nodes,msg)
    end

    def self.initiate_node_action(method,node,callbacks,context)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.send(method,node,callbacks,context)
    end
    # TODO: convert poll_to_detect_node_ready to use more general form above
    def self.poll_to_detect_node_ready(node,opts)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.poll_to_detect_node_ready(node,opts)
    end

   private
    def self.load_iaas_for(key_val)
      key = key_val.keys.first
      val = key_val.values.first
      adapter_name = 
        case key
          when :node
            node = val
            case iaas_type = node.get_iaas_type()
              when :ec2_instance then :ec2
              when :ec2_image then :ec2 #TODO: kept in because staged node has this type, which should be changed
              when :physical then :physical
            else raise Error.new("iaas type (#{iaas_type}) not treated")
            end
          when :target
            target =  val
            iaas_type = target.get_field?(:iaas_type)
            case iaas_type
              when "ec2" then :ec2
              when "physical" then :physical
            else raise Error.new("iaas type (#{iaas_type}) not treated")
            end
          when :image_type
            image_type = val
            case image_type
              when :ec2_image then :ec2
              else raise Error.new("image type (#{key_val[:image_type]}) not treated")
            end
          else
            raise Error.new("#{key_val.inspect} not treated")
        end
      adapter_type = :iaas
      load_for_aux(adapter_type,adapter_name)
    end
    
    def self.load_config_node_adapter()
      adapter_type = :node_config
      adapter_name = R8::Config[:command_and_control][adapter_type][:type]
      load_for_aux(adapter_type,adapter_name)
    end

    def self.load_for(task_or_task_action)
      adapter_type,adapter_name = task_or_task_action.ret_command_and_control_adapter_info()
      adapter_name ||= R8::Config[:command_and_control][adapter_type][:type]
      raise ErrorCannotLoadAdapter.new unless adapter_type and adapter_name
      load_for_aux(adapter_type,adapter_name)
    end

    def self.load_for_aux(adapter_type,adapter_name)
      Adapters[adapter_type] ||= Hash.new
      return Adapters[adapter_type][adapter_name] if Adapters[adapter_type][adapter_name]
      begin
        r8_nested_require("command_and_control","adapters/#{adapter_type}/#{adapter_name}")
        klass = CommandAndControlAdapter.const_get adapter_name.to_s.capitalize
        Adapters[adapter_type][adapter_name] =  (instance_style_adapter?(adapter_type,adapter_name) ? klass.new : klass)
       rescue LoadError => e
        raise ErrorUsage.new("IAAS type ('#{adapter_name}') not supported!")
       rescue Exception => e
        raise e
      end
    end
    Adapters = Hash.new
    Lock = Mutex.new
    # TODO: want to convert all adapters to new style to avoid setting stack error when adapter method not defined to have CommandAndControlAdapter self call instance
    def self.instance_style_adapter?(adapter_type,adapter_name)
      (InstanceStyleAdapters[adapter_type.to_sym]||[]).include?(adapter_name.to_sym)
    end
    InstanceStyleAdapters = {
      :iaas => [:physical]
    }

    #### Error classes
    class Error < XYZ::Error
      def to_hash()
        {:error_type => Aux.demodulize(self.class.to_s)}
      end
      class CannotConnect < Error
      end
      class Communication < Error
      end
      class CannotLoadAdapter < Error
      end
      class Timeout < Error
      end
      class FailedResponse < Error
        def initialize(error_msg)
          super()
          @error_msg = error_msg
        end
        def to_hash()
          super().merge(:error_msg => @error_msg)
        end 
      end
      class CannotCreateNode < Error
      end
      class WhileCreatingNode < Error
      end
    end
  end

  class CommandAndControlNodeConfig < CommandAndControl
  end

  class CommandAndControlIAAS < CommandAndControl
  end
end

