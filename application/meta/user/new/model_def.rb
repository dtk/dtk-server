{
  :schema=>:app_user, #cannot use schema user because reserved
  :table=>:user,
  :columns=>{
    :username => {:type=>:varchar, :size => 50},
    :password => {:type=>:varchar, :size => 50},
    :first_name => {:type=>:varchar, :size => 50},
    :last_name => {:type=>:varchar, :size => 50},
    :is_admin_user=> {:type=>:boolean},
    :email_addresses_primary => {:type=>:varchar, :size => 50},
    :settings => {:type=>:json},
    :status => {:type=>:varchar, :size => 50},
    :ssh_rsa_pub_keys => {:type=>:json}
  },
  :virtual_columns=>{
    :user_groups=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:user_group_relation,
         :join_type=>:left_outer,
         :join_cond=>{:user_id=>:user__id},
         :cols=>[:user_group_id]
       },
       {
         :model_name=>:user_group,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:id=>:user_group_relation__user_group_id},
         :cols=>[:id,:groupname]
       }]
    }
  },
  :one_to_many => [:access_rule]
}
