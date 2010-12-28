module XYZ
  class Workflow
    def self.create(ordered_actions)
      klass = self
      begin
        type = R8::Config[:workflow][:type]
        require File.expand_path("#{UTILS_DIR}/internal/workflow/adapters/#{type}", File.dirname(__FILE__))
        klass = XYZ::WorkflowAdapter.const_get type.capitalize
       rescue LoadError
        Log.error("cannot find workflow adapter; loading null workflow class")
      end
      klass.new(ordered_actions)
    end
    def execute()
    end
    def initialize(ordered_actions)
    end
  end
  module WorkflowAdapter
  end
end

