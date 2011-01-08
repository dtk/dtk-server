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
   protected
    def create_or_execute_on_node(node_actions)
      begin
        CommandAndControl::Adapter.dispatch_to_client(node_actions)
       rescue Exception => e
        Log.error("error in workflow create_or_execute_on_node: #{e.inspect}")
        config_agent = ConfigAgent.load(node_actions.on_node_config_agent_type)
        {:status => :failed,
          :node_name => config_agent.node_name(node_actions[:node]), 
          :error => e
        }
      end
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

