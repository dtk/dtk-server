{
  :schema=>:component,
  :table=>:ref,
  :columns=>{
    :component_template_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :many_to_one => [:node]
}
