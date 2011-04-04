
model_defs[:datacenter][:columns][:type][:length] = 100

model_defs[:datacenter][:columns][:new_field_01] = {
      :type=>:text,
      :length=>30
}
model_defs[:datacenter][:columns][:new_field_02] = {
      :type=>:int,
      :length=>11
}

model_defs[:datacenter][:one_to_many].push(:new_relationship)


model_defs[:datacenter][:virtual_columns][:new_virt_col] = {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:datacenter_datacenter_id=>:datacenter__id},
         :cols=>[:id,:display_name,:ui,:type]
       }]
}
