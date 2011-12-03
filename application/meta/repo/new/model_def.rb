{
  :schema=>:repo,
  :table=>:repo,
  :columns=>{
    :repo_name => {:type=>:varchar, :size => 100},
    :local_dir => {:type=>:varchar, :size => 100}
  },
  :one_to_many => [:repo_user_acl]
}
