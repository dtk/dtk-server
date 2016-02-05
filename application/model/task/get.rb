#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task
  module GetMixin
    def get_errors
      sp_hash = {cols: [:content]}
      get_children_objs(:task_error, sp_hash).map{|r|r[:content]}
    end
    # TODO: see why above does not leverage get_ndx_errors in contrast to below
    def get_logs?
      Task.get_ndx_logs([id_handle])[id]
    end

    # self should be a top level task
    def get_ordered_stage_level_tasks(start_stage, end_stage)
      filter = [:oneof, :position, Array(start_stage..end_stage)]
      stage_level_tasks = self.class.get_next_level_tasks([id_handle()], filter: filter)
      stage_level_tasks.sort{|a,b|a[:position] <=> b[:position]}
    end

    def get_config_agent_type(executable_action = nil, opts = {})
      executable_action ||= executable_action(opts)
      executable_action.config_agent_type() if executable_action && executable_action.respond_to?('config_agent_type')
    end
    
    private

    def get_config_agent
      ConfigAgent.load(get_config_agent_type())
    end
  end

  module GetClassMixin
    def get_top_level_most_recent_task(model_handle, filter = nil)
      # TODO: can be more efficient if do sql query with order and limit 1
      tasks = get_top_level_tasks(model_handle, filter).sort { |a, b| b[:updated_at] <=> a[:updated_at] }
      tasks && tasks.first
    end

    def get_top_level_tasks(model_handle, filter = nil)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :status, :updated_at, :executable_action_type, :commit_message],
        filter: [:and, [:eq, :task_id, nil], #so this is a top level task
                 filter].compact
      }
      get_objs(model_handle, sp_hash).reject { |k, _v| k == :subtasks }
    end

    def get_most_recent_top_level_task(model_handle)
      get_top_level_tasks(model_handle).sort { |a, b| b[:updated_at] <=> a[:updated_at] }.first
    end

    def get_ndx_errors(task_idhs)
      ret = {}
      return ret if task_idhs.empty?
      sp_hash = {
        cols:   [:task_id, :content],
        filter: [:oneof, :task_id, task_idhs.map{ |idh| idh.get_id() }]
      }
      task_error_mh = task_idhs.first.createMH(:task_error)
      get_objs(task_error_mh, sp_hash).each do |r|
        task_id = r[:task_id]
        (ret[task_id] ||= []) << r[:content]
      end
      ret
    end

    def get_ndx_logs(task_idhs)
      ret = {}
      return ret if task_idhs.empty?
      sp_hash = {
        cols:   [:task_id, :content, :display_name, :parent_task],
        filter: [:oneof, :task_id, task_idhs.map{ |idh| idh.get_id() }]
      }
      task_log_mh = task_idhs.first.createMH(:task_log)

      get_objs(task_log_mh, sp_hash).each do |r|
        task_id = r[:task_id]
        content = r[:content].merge(label: r[:display_name], task_name: r[:task][:display_name])
        (ret[task_id] ||= []) << content
      end
      ret
    end

    # returns an array of tasks; if :reify is true, each task's content is reified 
    def get_all_subtasks(task_idhs, opts = {})
      ret = []
      id_handles = task_idhs
      until id_handles.empty?
        next_level_objs = get_next_level_tasks(id_handles).reject{|k,v|k == :subtasks}.each{|st|opts[:reify] ? st.reify!() : st}
        id_handles = next_level_objs.map{|obj|obj.id_handle}
        ret += next_level_objs
      end
      ret
    end

    def get_next_level_tasks(task_idhs, opts = {})
      ret = []
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