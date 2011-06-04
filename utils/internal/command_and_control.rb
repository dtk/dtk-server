module XYZ
  module CommandAndControlAdapter
  end
  class CommandAndControl
    def self.execute_task_action(task_action,task,top_task_idh,opts={})
      klass = load_for(task_action)
      attributes_to_set = task_action.attributes_to_set()
      task_mh = task.model_handle()
      task_idh = task.id_handle()
      task_action.get_and_update_attributes(task_mh)
      if opts[:initiate_only]
        klass.initiate_execution(task_idh,top_task_idh,task_action,opts)
      else
        result = klass.execute(task_idh,top_task_idh,task_action)
        result.merge(:task_id => task.id())
      end
    end

    def self.get_and_propagate_updated_attributes(task_action)
      klass = load_for(task_action)
      updated_attributes = klass.get_updated_attributes(task_action)
      propagate_attributes(updated_attributes)
    end

    def self.get_logs(task,nodes)
      klass = load_for(task)
      klass.get_logs(task,nodes)
    end

    def self.create_poller_listener_connection()
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.create_poller_listener_connection()
    end

    def self.create_listener(connection)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.create_listener(connection)
    end

    def self.poll_to_detect_node_ready(node,opts)
      adapter_name = R8::Config[:command_and_control][:node_config][:type]
      klass = load_for_aux(:node_config,adapter_name)
      klass.poll_to_detect_node_ready(node,opts)
    end

   private
    def self.propagate_attributes(updated_attributes)
      return nil if updated_attributes.empty?
      #set attributes
      model_handle = updated_attributes.first.model_handle
      update_rows = updated_attributes.map{|attr|{:id => attr[:id], :value_asserted => attr[:value_asserted]}}
      Model.update_from_rows(model_handle,update_rows)
      AttributeLink.propagate(updated_attributes.map{|attr|attr.id_handle()})
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
       rescue LoadError
        nil
       rescue Exception => e
        raise e
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

