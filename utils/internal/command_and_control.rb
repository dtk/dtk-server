module XYZ
  module CommandAndControlAdapter
  end
  class CommandAndControl
    #### Error classes
    class Error < Exception
    end
    class ErrorCannotFindIdentity < Error
    end
    class ErrorCannotCreateNode < Error
    end
  end

  class CommandAndControlNodeConfig < CommandAndControl
    klass = self
    begin
      type = R8::Config[:command_and_control][:type]
      require File.expand_path("#{UTILS_DIR}/internal/command_and_control/adapters/node_config/#{type}", File.dirname(__FILE__))
      klass = XYZ::CommandAndControlAdapter.const_get type.capitalize
    rescue LoadError
      Log.error("cannot find command_and_control config control adapter; loading null command_and_control class")
    end
    Adapter = klass

    def self.dispatch_to_client(action,config_agent) 
      nil
    end    
  end

  class CommandAndControlIAAS < CommandAndControl
    def self.load(type)
      return Adapters[type] if Adapters[type]
      klass = self
      begin
        Lock.synchronize do
          require File.expand_path("#{UTILS_DIR}/internal/command_and_control/adapters/iaas/#{type}", File.dirname(__FILE__))
        end
        klass = XYZ::CommandAndControlAdapter.const_get type.to_s.capitalize
      rescue LoadError
        Log.error("cannot find command and control IAAS adapter; loading null one")
      end
      Adapters[type] = klass.new()
    end

    def create_node(create_node_action)
      new_node = create_node_implementation(create_node_action)
      raise ErrorCannotCreateNode.new unless new_node
      new_node
    end

   private
    Lock = Mutex.new
    Adapters = Hash.new
  end
end
