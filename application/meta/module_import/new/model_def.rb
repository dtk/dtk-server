{
  :schema=>:component,
  :table=>:module_import,
  :columns=>{
    :module_name=>{
      :type=>:varchar,
      :size =>50
    },
    :version=>{
      :type=>:varchar,
      :size =>25
    }
  },
  :many_to_one=>[:component]
}
