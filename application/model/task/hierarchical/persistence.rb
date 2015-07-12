module DTK; class Task
  module HierarchicalMixin
    module PersistenceMixin
      # saves hirerachical structure to db and returns task with top level and subtask ids filled out
      def save_and_add_ids
        save!()
        # TODO: this is simple but expensive way to get all teh embedded task ids filled out
        # can replace with targeted method that does just this
        Hierarchical.get_and_reify(id_handle())
      end
      
        # persists to db this and its sub tasks
      def save!
        # no op if saved already as detected by whether has an id
        return nil if id()
        set_positions!()
        # for db access efficiency implement into two phases: 1 - save all subtasks w/o ids, then put in ids
        unrolled_tasks = unroll_tasks()
        rows = unrolled_tasks.map do |hash_row|
          executable_action = hash_row[:executable_action]
          row = {
            display_name: hash_row[:display_name] || "task#{hash_row[:position]}",
            ref: "task#{hash_row[:position]}",
            executable_action_type: executable_action ? Aux.demodulize(executable_action.class.to_s) : nil,
            executable_action: executable_action
          }
          cols = [:status, :result, :action_on_failure, :position, :temporal_order, :commit_message]
          cols.each { |col| row.merge!(col => hash_row[col]) }
          [:assembly_id, :node_id, :target_id].each do |col|
            row[col] = hash_row[col] || SQL::ColRef.null_id
          end
          row
        end
        new_idhs = Model.create_from_rows(model_handle, rows, convert: true, do_not_update_info_table: true)
        unrolled_tasks.each_with_index { |task, i| task.set_id_handle(new_idhs[i]) }
        
        # set parent relationship and use to set task_id (subtask parent) and children_status
        par_rel_rows_for_id_info = set_and_ret_parents_and_children_status!()
        par_rel_rows_for_task = par_rel_rows_for_id_info.map { |r| { id: r[:id], task_id: r[:parent_id], children_status: r[:children_status] } }
        
        Model.update_from_rows(model_handle, par_rel_rows_for_task) unless par_rel_rows_for_task.empty?
        IDInfoTable.update_instances(model_handle, par_rel_rows_for_id_info)
      end
      
    end
  end
end; end
