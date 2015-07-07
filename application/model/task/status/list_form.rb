module DTK; class Task; class Status
  module ListForm
    # This method will return task details in form of list. It is used when CLI list-task-info is invoked
    def self.status(task_structure,model_handle)
      ret = {}

      ret[:task_id] = task_structure[:id]
      ret[:task_name] = task_structure[:display_name]
      ret[:temporal_order] = task_structure[:temporal_order]
      ret[:actions] = []

      level_1 = task_structure[:subtasks]
      level_1.each do |l1|
        level_1_ret = {}
        level_1_ret[:temporal_order] = l1[:temporal_order]
        level_1_ret[:task_name] = l1[:display_name]
        level_2 = [l1]
        level_2 = l1[:subtasks] if l1[:subtasks]
        level_1_ret[:nodes] = []
        level_2.each do |l2|
          level_2_ret = {}
          level_2_ret[:node_name] = l2[:executable_action][:node][:display_name]
          if l2[:executable_action_type] == "CreateNode"
            level_2_ret[:task_name] = "create_node"
            level_2_ret[:node_id] = l2[:executable_action][:node][:id]
            # Amar: Special case when 1 node present, to skip printing 'task1' on CLI for create_node_stage
            level_1_ret[:task_name] = "create_node_stage" if l1[:subtasks].nil? && l1[:display_name].include?("task")
          elsif l2[:executable_action_type] == "ConfigNode"
            level_2_ret[:task_name] = "config_node"
            level_2_ret[:components] = []
            level_3 = l2[:executable_action][:component_actions]            
            level_3.each do |l3|
              # Amar: Following condition block checks if 'node_node_id' from component is identical to node's 'id' 
              #       If two values are different, it means component came from node_group, and not from assembly instance
              #       Result is printing component source
              #       Check DTK-738 ticket for more details
              source = "instance"
              unless l3[:component][:node_node_id] == l2[:executable_action][:node][:id]
                node_group = NodeGroup.id_to_name(model_handle, l3[:component][:node_node_id])
                source = "node_group"
              end
              level_2_ret[:components] << 
              { component:                 {
                  component_name: l3[:component][:display_name], 
                  source: source, 
                  node_group: node_group 
                } 
              }
            end
          end
          level_1_ret[:nodes] << level_2_ret
        end
        ret[:actions] << level_1_ret
      end
      ret
    end
  end
end; end; end
