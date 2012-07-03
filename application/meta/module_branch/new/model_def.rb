lambda__matching_library_branches =
  lambda{|type|
  parent_col = (type == :service_module ? :service_id : :component_id)
  {
    :type => :json, 
    :hidden => true,
    :remote_dependencies =>
    [{
       :model_name => :module_branch,
       :convert => true,
       :alias => :library_module_branch,
       :join_type => :inner,
       :join_cond=>{:version => q(:module_branch,:version),parent_col => q(:module_branch,parent_col)},
       :filter => [:eq,:is_workspace,false],
       :cols => [:id,:display_name,:repo_id,:branch,:version]
     },
     {
       :model_name => type,
       :convert => true,
       :join_type => :inner,
       :join_cond=>{:id => q(:library_module_branch,parent_col)},
       :cols => [:id,:display_name,:library_library_id]
     }
    ]
  }
}
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
    },
    :matching_component_library_branches=> lambda__matching_library_branches.call(:component_module),
    :matching_service_library_branches=> lambda__matching_library_branches.call(:service_module)
  },
  :many_to_one=>[:component_module,:service_module]
}
