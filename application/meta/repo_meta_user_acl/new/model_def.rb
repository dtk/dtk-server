{
  :schema=>:repo,
  :table=>:user_acl,
  :columns=>{
    :repo_meta_user_id =>{
      :type=>:bigint,
      :foreign_key_rel_type=>:repo_meta_user,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :access_rights => {:type=>:json}
  },
  :many_to_one=> [:repo_meta]
}
