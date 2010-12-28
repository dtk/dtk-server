module XYZ
  class Workflow
    def self.create(action_list)
      klass = self
      begin
        type = R8::Config[:workflow][:type]
        require File.expand_path("#{UTILS_DIR}/internal/workflow/adapters/#{type}", File.dirname(__FILE__))
        klass = XYZ::WorkflowAdapter.const_get type.capitalize
       rescue LoadError
        Log.error("cannot find workflow adapter; loading null workflow class")
      end
      klass.new(action_list)
    end
    def execute()
    end
    def initialize(action_list)
    end
  end
  module WorkflowAdapter
  end
end

