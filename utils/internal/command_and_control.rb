module XYZ
  module CommandAndControlAdapter
  end
  class CommandAndControl
    def self.execute_task_action(task,top_task_idh,opts={})
      task_action = task[:executable_action]
      klass = load_for(task_action)
      task_idh = task.id_handle()
      if opts[:initiate_only]
        klass.initiate_execution(task_idh,top_task_idh,task_action,opts)
      else
        result = klass.execute(task_idh,top_task_idh,task_action)
        result.merge(:task_id => task.id())
      end
    end

    def self.destroy_node?(node)
      klass = load_iaas_for(:node => node)
      klass.destroy_node?(node)
    end

    def self.get_node_state(node)
      adapter_name = R8::Config[:command_and_control][:iaas][:type]
      klass = load_for_aux(:iaas,adapter_name)      
      klass.get_node_state(node)
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

    def self.poll_to_detect_node_ready(node,opts)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.poll_to_detect_node_ready(node,opts)
    end

   private
    def self.load_iaas_for(key_val)
      if key_val[:node]
        node = key_val[:node]
        ext_ref_type = (node[:external_ref]||{})[:type]
        adapter_name = 
          case ext_ref_type
            when "ec2_instance" then :ec2
            when "ec2_image" then :ec2 #TODO: kept in because staged node has this type, which should be changed
           else raise Error.new("not treated")
        end
        adapter_type = :iaas
        load_for_aux(adapter_type,adapter_name)
      else
        raise Error.new("not treated")
      end
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
        require File.expand_path("#{UTILS_DIR}/internal/command_and_control/adapters/#{adapter_type}/#{adapter_name}", File.dirname(__FILE__))
        Adapters[adapter_type][adapter_name] = XYZ::CommandAndControlAdapter.const_get adapter_name.to_s.capitalize
       rescue LoadError => e
        raise e
       rescue Exception => e
        raise e
      end
    end
    Adapters = Hash.new
    Lock = Mutex.new

   public
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

