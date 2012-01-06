{
  :schema=>:task,
  :table=>:task,
  :columns=>{
    :status => {:type=>:varchar, :size=>20, :default => "created"}, # = "created" | "executing" | "succeeded" | "failed" 
    :start_datetime => {:type => :timestamp},
    :end_datetime => {:type => :timestamp},
    :result => {:type => :json}, # gets serialized version of TaskAction::Result
    :action_on_failure => {:type => :varchar, :default => "abort"},
    :commit_message => {:type => :varchar}, #only on top level task
    :temporal_order => {:type => :varchar, :size => 20}, # = "sequential" | "concurrent"
    :position => {:type => :integer, :default => 1},
    :executable_action_type => {:type => :varchar},
    :executable_action => {:type => :json}, #gets serialized version of TaskAction::Action
    :children_status => {:type => :json}, #caching children status; hash of form {child1_id => status1, ..}
    #TODO: the value of this in relation to attributes in executable action is confusing; these have the updated attribute values
    :bound_input_attrs => {:type => :json},
    :bound_output_attrs => {:type => :json} #these are the dynamic attributes with values at time of task completion
  },
  :many_to_one=>[:project,:task],
  :one_to_many => [:task, :task_log, :task_event, :task_error]
}

