{
  :schema=>:module,
  :table=>:branch,
  :columns=>{
    :branch => {:type=>:varchar, :size => 50},
    :version => {:type=>:varchar, :size => 20},
    :is_workspace => {:type =>:boolean},
    :type => {:type=>:varchar, :size => 20}, #service_module or component_module
    :repo_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:repo,
      :on_delete=>:set_null,
      :on_update=>:set_null
    },
    :project_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:project,
      :on_delete=>:cascade,
      :on_update=>:cascade
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
