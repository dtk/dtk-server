{
  :schema=>:task,
  :table=>:log,
  :columns=>{
    :status => {:type=>:varchar, :size=>20, :default => "empty"}, # = "in_progress" | "complete"
    :type => {:type=>:varchar, :size=>20}, # "chef" || "puppet"
    :content => {:type =>:json}
  },
  :many_to_one=>[:task],
  :virtual_columns=>{
    :parent_task=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:task,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:task_id},
        :cols => [:id,:display_name]
       }]
    }
  }
}

