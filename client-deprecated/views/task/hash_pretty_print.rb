module DTK::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :task,
    :defs => {
      :task_def =>
      [
       :commit_message,
       :type,
       :id,
       :status,
       {:node  => {:type => :node}},
       :created_at,
       :started_at,
       :ended_at,
       :temporal_order,
       {:subtasks => {:type => :task, :is_array => true}},
       :errors #{:errors => {:type => :error, :is_array => true}} 
      ],
      :node_def => [:name, :id],
      :error_def => [:component, :message]
    }
  }
end

