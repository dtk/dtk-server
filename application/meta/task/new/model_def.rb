{
  :schema=>:task,
  :table=>:task,
  :columns=>{
    :status => {:type=>:varchar, :size=>20, :default => "created"}, # = "created" | "executing" | "completed" | "failed" | "not_reached"
    :result => {:type => :json}, # gets serialized version of TaskAction::Result
    :action_on_failure => {:type => :varchar, :default => "abort"},
    :temporal_order => {:type => :varchar, :size => 20}, # = "sequential" | "concurrent"
    :position => {:type => :integer, :default => 1},
    :executable_action_type => {:type => :varchar},
    :executable_action => {:type => :json}, #gets serialized version of TaskAction::Action
  },
  :many_to_one=>[:task],
  :one_to_many => [:task, :task_event, :task_error]
}

