{
  :schema=>:access,
  :table=>:rule,
  :columns=>{
    :object_handle => {:type=>:json},
    :operation_type => {:type=>:varchar,:length=>20}
  },
  :many_to_one=>[:user,:user_group]
}
