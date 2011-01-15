module XYZ
  module CommandAndControlAdapter
  end
  class CommandAndControl
    def self.execute_task_action(task_action,task)
      klass = load_for(task_action)
      raise ErrorCannotLoadAdapter.new unless klass
      attributes_to_set = (task_action[:attributes]||[]).reject{|a| not a[:dynamic]}
      pp [:attributes_to_set,attributes_to_set]
      task_mh = task.model_handle()
      task_action.get_and_update_attributes(task_mh)
      ret = klass.execute(task_action,attributes_to_set)
      #TODO: set and propgate any dyanmic attributes set
      ret
    end

    #TODO: temp hack
    def self.wait_for_node_to_be_ready(node) 
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.wait_for_node_to_be_ready(node)
    end

   private
    def self.load_for(task_action)
      adapter_type,adapter_name = task_action.ret_command_and_control_adapter_info()
      adapter_name ||= R8::Config[:command_and_control][adapter_type][:type]
      return nil unless adapter_type and adapter_name
      load_for_aux(adapter_type,adapter_name)
    end

    def self.load_for_aux(adapter_type,adapter_name)
      Adapters[adapter_type] ||= Hash.new
      return Adapters[adapter_type][adapter_name] if Adapters[adapter_type][adapter_name]
      begin
        require File.expand_path("#{UTILS_DIR}/internal/command_and_control/adapters/#{adapter_type}/#{adapter_name}", File.dirname(__FILE__))
        Adapters[adapter_type][adapter_name] = XYZ::CommandAndControlAdapter.const_get adapter_name.to_s.capitalize
       rescue LoadError
        nil
      end
    end
    Adapters = Hash.new
    Lock = Mutex.new

   public
    #### Error classes
    class Error < Exception
    end
    class ErrorCannotConnect < Error
    end
    class ErrorCannotLoadAdapter < Error
    end
    class ErrorTimeout < Error
    end
    class ErrorFailedResponse < Error
      def initialize(response_status,response_error)
        super()
        @response_status = response_status
        @response_error = response_error
      end
      def debug_pp_form()
        [self.class,{:response_status => @response_status,:response_error => @response_error}]
      end
    end
    class ErrorCannotCreateNode < Error
    end
    class ErrorWhileCreatingNode < Error
    end
  end

  class CommandAndControlNodeConfig < CommandAndControl
  end

  class CommandAndControlIAAS < CommandAndControl
  end
end
