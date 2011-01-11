#TODO: need to pass back return for all actions; now if do create and update; only update put in
module XYZ
  module WorkflowAdapter
  end

  class Workflow
    def self.create(ordered_actions)
      Adapter.new(ordered_actions)
    end
    def execute()
      results = execute_implementation()
#TODO: for some reason this debug statement does not spit ot instance mebers of error
##pp [:results, results]
puts "------------results-------------"
(results||{}).each do |key,result|
  if result[:error] and result[:error].respond_to?(:debug_pp_form)
    puts Aux::pp_form({key => result.merge(:error => result[:error].debug_pp_form)})
  else
    #TODO: very weir getting parsing error for pp {key => result}
    x = Hash.new; x[key]=result; pp x
  end
end
puts "------------end results-------------"
      results
#### end of debug
    end
    def initialize(ordered_actions)
    end
   protected
    def self.create_or_execute_on_node(node_actions)
      ret = nil
      begin
        #check if there is a create node action and if so do it first
        if node_actions.create_node_state_change
          cac_iaas = CommandAndControlIAAS.load(node_actions.create_node_config_agent_type)
          node_actions.node =  cac_iaas.create_node(node_actions.create_node_state_change)
          if node_actions.node
            CommandAndControlNodeConfig::Adapter.wait_for_node_to_be_ready(node_actions.node) 
            #TODO: save_new_node_info() should be before wait
            node_actions.save_new_node_info()
            ret = {
              :status => :succeeded,
              :operation => :create_node,
              :node_name => node_actions.node[:display_name],
            }
            node_actions.update_state_create_node(:completed)
          end
        end
        if node_actions.any_on_node_changes?()
          ret = CommandAndControlNodeConfig::Adapter.dispatch_to_client(node_actions)
        end
        node_actions.update_state_on_node_changes(:completed)
       rescue Exception => e
        #TODO: right now for failure not making change to node_actions state
        ret = {
          :status => :failed,
          :error => e,
          :node_name => node_actions.node[:display_name], 
        }
        #if internal error print trace
        pp [e,e.backtrace] unless e.kind_of?(CommandAndControl::Error)
      end
      ret
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

