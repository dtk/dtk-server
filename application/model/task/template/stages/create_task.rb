module DTK; class Task; class Template
  class Stages; class Internode
    module CreateTaskMixin
      def create_subtasks(task_mh,assembly_idh)
        ret = Array.new
        return ret if empty?()
        all_actions = Array.new
        each_with_index do |internode_stage,inter_node_stage_index|
          pp [internode_stage.class,internode_stage.serialization_form()]
=begin          

          ret = create_new_task(task_mh,:display_name => "config_node_stage#{stage_index}", :temporal_order => "concurrent")
        all_errors = Array.new
        state_change_list.each do |sc|
          executable_action, error_msg = get_executable_action_from_state_change(sc, assembly_idh, stage_index)
          unless executable_action
            all_errors << error_msg
            next
          end
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
        end
        raise ErrorUsage.new("\n" + all_errors.join("\n")) unless all_errors.empty?
      end
      attr_mh = task_mh.createMH(:attribute)
      Task::Action::ConfigNode.add_attributes!(attr_mh,all_actions)
      ret
    end
=end
        end
      end
    end
  end; end
end; end; end
    
