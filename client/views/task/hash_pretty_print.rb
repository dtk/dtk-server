module R8::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :task,
    :defs => {
      :task_def =>
      [
       :type,
       :status,
       {:subtasks => {:type => :task, :is_array => true}}
      ]
    }
  }
end

