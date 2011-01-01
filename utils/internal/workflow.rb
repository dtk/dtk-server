module XYZ
  module WorkflowAdapter
  end

  class Workflow
    def self.create(ordered_actions)
      Adapter.new(ordered_actions)
    end
    def execute()
    end
    def initialize(ordered_actions)
    end

   private
    klass = self
    begin
      type = R8::Config[:workflow][:type]
      require File.expand_path("#{UTILS_DIR}/internal/workflow/adapters/#{type}", File.dirname(__FILE__))
      klass = XYZ::WorkflowAdapter.const_get type.capitalize
     rescue LoadError
      Log.error("cannot find workflow adapter; loading null workflow class")
    end
    Adapter = klass
  end
end

