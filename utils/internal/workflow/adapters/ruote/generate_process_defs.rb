module XYZ
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      @@count = 0
      def compute_process_def()
        #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        @@count += 1
        top_task_idh = @task.id_handle()
        name = "process-#{@@count.to_s}"
        ["define", 
         {"name" => name},
         [["sequence", {}, 
          [compute_process_body(@task,top_task_idh),
           ["participant",{"ref" => "end_of_task"},[]]]]]]
      end

      def compute_process_body(task,top_task_idh)
        executable_action = task[:executable_action]
        if executable_action
          task_info = {
            "action" => executable_action,
            "workflow" => self,
            "top_task_idh" => top_task_idh
          }
          task_id = task.id()
          Ruote.push_on_object_store(task_id,task_info)

          ["participant", 
           {"ref" => "execute_on_node", 
            "task_id" => task_id,
             "top_task_idh" => top_task_idh
           },
           []]

#test
test_task_id = "#{task_id.to_s}-test"
Ruote.push_on_object_store(test_task_id,task_info)
          ["sequence", {},
            [["participant",
             {"ref" => "test",
               "task_id" => test_task_id,
               "top_task_idh" => top_task_idh
             },[]],
          ["participant", 
           {"ref" => "execute_on_node", 
            "task_id" => task_id,
             "top_task_idh" => top_task_idh
           },
           []]]]

        elsif task[:temporal_order] == "sequential"
          compute_process_body_sequential(task.subtasks,top_task_idh)
        elsif task[:temporal_order] == "concurrent"
          compute_process_body_concurrent(task.subtasks,top_task_idh)
        else
          Log.error("do not have rules to process task")
        end
      end
      def compute_process_body_sequential(subtasks,top_task_idh)
        ["sequence", {}, subtasks.map{|t|compute_process_body(t,top_task_idh)}]
      end
      def compute_process_body_concurrent(subtasks,top_task_idh)
        ["concurrence", {"merge_type"=>"stack"}, subtasks.map{|t|compute_process_body(t,top_task_idh)}]
      end
    end
  end
end
