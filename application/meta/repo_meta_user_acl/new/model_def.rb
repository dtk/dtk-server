{
  :schema=>:repo,
  :table=>:user_acl,
  :columns=>{
    :repo_id =>{
      :type=>:bigint,
      :foreign_key_rel_type=>:repo_meta,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :access_rights => {:type=>:json}
  },
  :many_to_one=> [:repo_meta_user]
}
