#TODO: need to pass back return for all actions; now if do create and update; only update put in
module XYZ
  module WorkflowAdapter
  end

  class Workflow
    def self.create(task)
      Adapter.new(task)
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
   protected
    #TODO: iterating towards treating relationship between create_node config_node in generic way with a
    #paramter dependency link
    def self.create_or_execute_on_node(create_node,config_node)
      ret = nil
      node = (create_node||config_node)[:node]
      begin
        #check if there is a create node action and if so do it first
        if create_node
          new_node_info = CommandAndControl.execute_task_action(create_node)
          if new_node_info
            create_node[:node] = new_node_info
            create_node.save_new_node_info()
            CommandAndControl.wait_for_node_to_be_ready(create_node[:node])
            ret = {
              :status => :succeeded,
              :operation => :create_node,
              :node_name => create_node[:node][:display_name],
            }
            create_node.update_state(:completed)
          end
        end
        if config_node
          ret = CommandAndControl.execute_task_action(config_node)
        end
        config_node.update_state(:completed)
       rescue Exception => e
        #TODO: right now for failure not making change to node_actions state
        ret = {
          :status => :failed,
          :error => e,
          :node_name => node[:display_name], 
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

