{
  :schema=>:module,
  :table=>:branch,
  :columns=>{
    :branch => {:type=>:varchar, :size => 50},
    :version => {:type=>:varchar, :size => 20},
    :is_workspace => {:type =>:boolean},
    :repo_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:repo,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{
    :prety_print_version=>{
      :type=>:varchar,
      :hidden=>true,
      :local_dependencies => [:branch,:version]
    }
  },
  :many_to_one=>[:component_module,:service_module]
}
