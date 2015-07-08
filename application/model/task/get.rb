module DTK; class Task
  module GetMixin
    def get_errors
      sp_hash = {
        :cols => [:content]
      }
      get_children_objs(:task_error,sp_hash).map{|r|r[:content]}
    end

    # indexed by task ids
    def get_ndx_errors
      self.class.get_ndx_errors(hier_task_idhs())
    end
    
    def get_logs
      ret_logs = Hash.new
      sp_hash = {:cols => [:task_id, :display_name, :content, :parent_task]}
      ret = get_children_objs(:task_log, sp_hash).sort{|a,b| a[:created_at] <=> b[:created_at]}

      ret.each do |r|
        task_id = r[:task_id]
        content = r[:content] || Hash.new
        content.merge!({:label => r[:display_name], :task_name => r[:task][:display_name]})
        ret_logs[task_id] = (ret_logs[task_id]||Array.new) + [content]
      end

      ret_logs
    end

    def get_ndx_logs
      self.class.get_ndx_logs(hier_task_idhs())
    end

    def get_associated_nodes
      ndx_nodes = Hash.new
      get_leaf_subtasks().each do |subtask|
        if node = (subtask[:executable_action]||{})[:node]
          ndx_nodes[node.id()] ||= node
        end
      end
      ndx_nodes.values
    end

    def get_leaf_subtasks
      if subtasks = self[:subtasks]
        subtasks.inject(Array.new){|a,st|a+st.get_leaf_subtasks()}
      else
        [self]
      end
    end

    def get_config_agent_type(executable_action=nil, opts={})
      executable_action ||= executable_action(opts)
      executable_action.config_agent_type() if executable_action && executable_action.respond_to?('config_agent_type')
    end
    # self should be top level task
    def get_hierarchical_structure
      self.class.get_hierarchical_structure(id_handle())
    end

    # recursively walks structure, but returns them in flat list
    def get_all_subtasks
      self.class.get_all_subtasks([id_handle()])
    end
    def get_all_subtasks_with_logs
      self.class.get_all_subtasks_with_logs([id_handle])
    end

   private
    def get_config_agent
      ConfigAgent.load(get_config_agent_type())
    end   
  end

  module GetClassMixin
    def get_top_level_most_recent_task(model_handle,filter=nil)
      # TODO: can be more efficient if do sql query with order and limit 1
      tasks = get_top_level_tasks(model_handle,filter).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
      tasks && tasks.first
    end

    def get_top_level_tasks(model_handle,filter=nil)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:status,:updated_at,:executable_action_type,:commit_message],
        :filter => [:and,[:eq,:task_id,nil], #so this is a top level task
                    filter].compact
      }
      get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}
    end

    def get_most_recent_top_level_task(model_handle)
      get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}.first
    end

    def get_hierarchical_structure(top_task_idh)
      sp_hash = {
        :cols => Task.common_columns(),
        :filter => [:eq, :id, top_task_idh.get_id()]
      }
      top_task = get_objs(top_task_idh.createMH(),sp_hash).first
      return nil unless top_task
      flat_subtask_list = top_task.get_all_subtasks()
      ndx_task_list = {top_task.id => top_task}
      subtask_count = Hash.new
      subtask_indexes = Hash.new
      flat_subtask_list.each do |t|
        ndx_task_list[t.id] = t
        parent_id = t[:task_id]
        subtask_count[parent_id] = (subtask_count[parent_id]||0) +1
        subtask_indexes[t.id] = {:parent_id => parent_id,:index => t[:position]}
      end

      subtask_qualified_indexes = QualifiedIndex.compute!(subtask_indexes,top_task)

      flat_subtask_list.each do |subtask|
        subtask[QualifiedIndex::Field] = subtask_qualified_indexes[subtask[:id]][QualifiedIndex::Field]
        parent_id = subtask[:task_id]
        parent = ndx_task_list[parent_id]
        if subtask.node_group_member?()
          subtask.set_node_group_member_executable_action!(parent)
        end
        (parent[:subtasks] ||= Array.new(subtask_count[parent_id]))[subtask[:position]-1] = subtask
      end
      top_task
    end

    def get_ndx_errors(task_idhs)
      ret = Array.new
      return ret if task_idhs.empty?
      sp_hash = {
        :cols => [:task_id,:content],
        :filter => [:oneof,:task_id,task_idhs.map{|idh|idh.get_id()}]
      }
      task_error_mh = task_idhs.first.createMH(:task_error)
      ret = Hash.new
      get_objs(task_error_mh,sp_hash).each do |r|
        task_id = r[:task_id]
        ret[task_id] = (ret[task_id]||Array.new) + [r[:content]]
      end
      ret
    end

    def get_ndx_logs(task_idhs)
      ret = Array.new
      return ret if task_idhs.empty?
      sp_hash = {
        :cols => [:task_id, :content, :display_name, :parent_task],
        :filter => [:oneof, :task_id, task_idhs.map{|idh|idh.get_id()}]
      }
      task_log_mh = task_idhs.first.createMH(:task_log)
      ret = Hash.new
      get_objs(task_log_mh, sp_hash).each do |r|
        task_id = r[:task_id]
        content = r[:content]
        content.merge!({:label => r[:display_name], :task_name => r[:task][:display_name]})
        ret[task_id] = (ret[task_id]||Array.new) + [content]
      end
      ret
    end

    def get_all_subtasks(top_id_handles)
      ret = Array.new
      id_handles = top_id_handles
      until id_handles.empty?
        model_handle = id_handles.first.createMH()
        sp_hash = {
          :cols => Task.common_columns(),
          :filter => [:oneof,:task_id,id_handles.map{|idh|idh.get_id}]
        }
        next_level_objs = get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}
        next_level_objs.each{|st|st.reify!()}
        id_handles = next_level_objs.map{|obj|obj.id_handle}

        ret += next_level_objs
      end
      ret
    end

    def get_all_subtasks_with_logs(top_id_handles)
      ret = Array.new
      id_handles = top_id_handles
      until id_handles.empty?
        model_handle = id_handles.first.createMH()
        sp_hash = {
          :cols => [:id, :display_name],
          :filter => [:oneof, :task_id, id_handles.map{|idh|idh.get_id}]
        }
        next_level_objs = get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}
        next_level_objs.each{|st|st.reify!()}
        id_handles = next_level_objs.map{|obj|obj.id_handle}

        ret += next_level_objs
      end
      ret
    end

  end
end; end
