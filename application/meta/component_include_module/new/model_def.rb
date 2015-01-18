{
  :schema=>:component,
  :table=>:include_module,
  :columns=>{
    :version_constraint=>{
      :type=>:json
    },
    # gets set when resolved this to particular version
    :implementation_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:implementation,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{
    :implementation=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:implementation,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:id=>:component_include_module__implementation_id},
         :cols=>Implementation.common_columns()
       }]
    }
  },
  :many_to_one=>[:component]
}
