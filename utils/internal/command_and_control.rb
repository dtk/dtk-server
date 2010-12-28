module XYZ
  class CommandAndControl
    def self.create()
      klass = self
      begin
        type = R8::Config[:command_and_control][:type]
        require File.expand_path("#{UTILS_DIR}/internal/command_and_control/adapters/#{type}", File.dirname(__FILE__))
        klass = XYZ::CommandAndControlAdapter.const_get type.capitalize
       rescue LoadError
        Log.error("cannot find command_and_control adapter; loading null command_and_control class")
      end
      klass.new()
    end
    def dispatch_to_client(action) 
      nil
    end
   private
     def initialize()
     end
  end
   module CommandAndControlAdapter
   end
end
