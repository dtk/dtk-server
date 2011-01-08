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
        #check if there is a create node action and if so do it first
        if node_actions.create_node_action
          create_node_agent = ConfigAgent.load(node_actions.create_node_config_agent_type)
          node_actions.node =  create_node_agent.create_node(node_actions.create_node_action)
          raise CommandAndControl::CannotCreateNode.new unless node_actions.node
        end
        CommandAndControl::Adapter.dispatch_to_client(node_actions)
       rescue Exception => e
        ret = {
          :status => :failed,
          :error => e
        }
        config_agent = ConfigAgent.load(node_actions.on_node_config_agent_type)
        ret.merge!(:node_name => config_agent.node_name(node_actions.node)) if node_actions.node
        ret
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

