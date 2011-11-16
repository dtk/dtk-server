module Ramaze::Helper
  module TaskHelper
    def get_most_recent_task()
      tasks = XYZ::Task.get_top_level_tasks(model_handle(:task)).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
      tasks.first
    end
  end
end
