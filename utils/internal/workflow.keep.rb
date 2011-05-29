#TODO: need to pass back return for all actions; now if do create and update; only update put in
module XYZ
  module WorkflowAdapter
  end

  class Workflow
    def self.create(task)
      Adapter.new(task)
    end
    #virtual fn gets ovewritten
    def execute()
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

