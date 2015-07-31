module DTK
  class TaskController < AuthController
    helper :task_helper

    def rest__status
      task_id, detail_level =  ret_request_params(:task_id, :detail_level)
      detail_level =  (detail_level || :summary).to_sym
      unless task_id
        # TODO: use Task.get_top_level_most_recent_task(model_handle,filter=nil)
        tasks = Task.get_top_level_tasks(model_handle).sort { |a, b| b[:updated_at] <=> a[:updated_at] }
        task_id = tasks.first[:id]
      end
      opts = Hash.new
      if detail_level == :summary
        opts.merge!(no_components: true, no_attributes: true)
      end

      task_structure = Task::Hierarchical.get_and_reify(id_handle(task_id))
      state_info = task_structure.status_hash_form(opts)
      rest_ok_response state_info
    end

    def rest__create_task_from_pending_changes
      scope_x = ret_request_params(:scope) || {}
      # TODO: put in check/error that there is no task created already, but not executed, that handles same changes

      # process raw scope
      scope =
        if scope_x['target_ids']
          # TODO: stub
        elsif scope_x['project_id']
          sp_hash = {
            cols: [:id],
            filter: [:and, :project_project_id, scope_x['project_id'].to_i]
           }
          target_ids = Model.get_objs(model_handle(:target), sp_hash).map { |r| r[:id] }
          { target_ids: target_ids }
        else
          # TODO: stub if scope by node_id
          Log.info("node_id scope given (#{scope_x['node_id']})") if scope_x['node_id']
          target_ids = Model.get_objs(model_handle(:target), cols: [:id]).map { |r| r[:id] }
          { target_ids: target_ids }
        end
      return Error.new('Only treating scope by target ids') unless target_scope = scope[:target_ids]
      return Error.new('Only treating scope given by single target') unless target_scope.size == 1

      target_idh = id_handle(target_scope.first, :target)
      pending_changes = StateChange.flat_list_pending_changes(target_idh)

      if pending_changes.empty?
        rest_notok_response code: :no_pending_changes
      else
        task = Task.create_from_pending_changes(target_idh, pending_changes)
        task.save!()
        rest_ok_response task_id: task.id
      end
    end

    def rest__execute
      task_id =  ret_non_null_request_params(:task_id)
      task = Task::Hierarchical.get_and_reify(id_handle(task_id))
      workflow = Workflow.create(task)
      Aux.stop_for_testing?(:converge) # TODO: for debugging
      workflow.defer_execution()
      rest_ok_response task_id: task_id
    end

    def rest__cancel_task
      top_task_id = ret_non_null_request_params(:task_id)
      cancel_task(top_task_id)
      rest_ok_response task_id: top_task_id
    end

    def rest__create_converge_state_changes
      node_id = ret_request_params(:node_id)
      if node_id
        node_idhs = [id_handle(node_id, :node)]
      else
        # means get set of nodes
        # TODO: stub is to get all in target
        sp_hash = {
          cols: [:id, :display_name],
          filter: [:neq, :datacenter_datacenter_id, nil]
        }
        node_idhs = Model.get_objs(model_handle(:node), sp_hash).map(&:id_handle)
      end
      StateChange.create_converge_state_changes(node_idhs)
      rest_ok_response
    end
  end
end
