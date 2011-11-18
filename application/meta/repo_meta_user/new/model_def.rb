{
  :schema=>:repo,
  :table=>:user,
  :columns=>{
    :user_name => {:type=>:varchar, :size => 50},
    :access_rights => {:type=>:json}
  },
  :many_to_one=> [:repo_meta]
}
