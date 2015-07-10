module DTK; class Task
  module GetMixin
    def get_errors
      sp_hash = {cols: [:content]}
      get_children_objs(:task_error, sp_hash).map{|r|r[:content]}
    end

    def get_logs
      ret = Hash.new
      sp_hash = {cols: [:task_id, :display_name, :content, :parent_task]}
      rows = get_children_objs(:task_log, sp_hash).sort{|a,b| a[:created_at] <=> b[:created_at]}
      
      rows.each do |r|
        task_id = r[:task_id]
        content = r[:content] || Hash.new
        content.merge!({:label => r[:display_name], :task_name => r[:task][:display_name]})
        ret[task_id] = (ret[task_id]||Array.new) + [content]
      end
      
      ret
    end

    # self should be a top level task
    def get_ordered_stage_level_tasks(start_stage,end_stage)
      filter = [:oneof, :position, Array(start_stage..end_stage)]
      stage_level_tasks = self.class.get_next_level_tasks([id_handle()], filter: filter)
      stage_level_tasks.sort{|a,b|a[:position] <=> b[:position]}
    end

    def get_config_agent_type(executable_action=nil, opts={})
      executable_action ||= executable_action(opts)
      executable_action.config_agent_type() if executable_action && executable_action.respond_to?('config_agent_type')
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

    def get_ndx_errors(task_idhs)
      ret = Hash.new
      return ret if task_idhs.empty?
      sp_hash = {
        cols:   [:task_id,:content],
        filter: [:oneof,:task_id,task_idhs.map{|idh|idh.get_id()}]
      }
      task_error_mh = task_idhs.first.createMH(:task_error)
      ret = Hash.new
      get_objs(task_error_mh,sp_hash).each do |r|
        task_id = r[:task_id]
        ret[task_id] = (ret[task_id]||Array.new) + [r[:content]]
      end
      ret
    end

    # returns an array of tasks with task content reified 
    def get_and_reify_all_subtasks(task_idhs,opts={})
      ret = Array.new
      id_handles = task_idhs
      until id_handles.empty?
        next_level_objs = get_next_level_tasks(id_handles).reject{|k,v|k == :subtasks}.each{|st|st.reify!()}
        id_handles = next_level_objs.map{|obj|obj.id_handle}
        ret += next_level_objs
      end
      ret
    end

    def get_next_level_tasks(task_idhs,opts={})
      ret = Array.new
      return ret if task_idhs.empty?
      filter = [:oneof, :task_id, task_idhs.map{|idh|idh.get_id}]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols:   opts[:cols] || common_columns(),
        filter: filter
      }
      model_handle = task_idhs.first.createMH()
      get_objs(model_handle,sp_hash)
    end

  end
end; end
