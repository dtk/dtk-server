{
  :schema=>:component,
  :table=>:include_module,
  :columns=>{
    :module_name=>{
      :type=>:varchar,
      :size =>50
    },
    :version_constraint=>{
      :type=>:json
    }
  },
  :many_to_one=>[:component]
}
