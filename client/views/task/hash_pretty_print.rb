module R8::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :task,
    :defs => {
      :task_def =>
      [
       :commit_message,
       :type,
       :id,
       :status,
       :node,
       :started_at,
       :ended_at,
       :temporal_order,
       {:subtasks => {:type => :task, :is_array => true}},
       :errors
      ]
    }
  }
end

