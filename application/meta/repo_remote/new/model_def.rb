{
  :schema=>:repo,
  :table=>:remote,
  :columns=>{
    :repo_id =>{
      :type=>:bigint,
      :foreign_key_rel_type=>:repo,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :repo_name => {:type=>:varchar, :size => 100},
    :repo_namespace => {:type=>:varchar, :size => 30}
  },
  :many_to_one=> [:repo]
}
