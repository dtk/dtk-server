{
  :schema=>:repo,
  :table=>:user,
  :columns=>{
    :user_name => {:type=>:varchar, :size => 50}
  },
  :one_to_many => [:repo_meta_user_acl]
}
