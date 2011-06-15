{
  :schema=>:task,
  :table=>:log,
  :columns=>{
    :status => {:type=>:varchar, :size=>20, :default => "empty"}, # = "in_progress" | "complete"
    :type => {:type=>:varchar, :size=>20}, # "chef" || "puppet"
    :content => {:type =>:json}
  },
  :many_to_one=>[:task]
}

