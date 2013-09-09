lambda__matching_library_branches =
  lambda{|args|
  parent_col = (args[:type] == :service_module ? :service_id : :component_id)
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
       :model_name => args[:type],
       :convert => true,
       :join_type => :inner,
       :join_cond=>{:id => q(:library_module_branch,parent_col)},
       :cols => [:id,:display_name,:library_library_id]
     },
     {
       :model_name => :implementation,
       :convert => true,
       :join_type => :left_outer,
       :join_cond=>{:repo_id => q(:library_module_branch,:repo_id),:branch => q(:library_module_branch,:branch)},
       :cols => [:id,:group_id,:display_name]
     },
     {
       :model_name => :repo,
       :convert => true,
       :join_type => :inner,
       :join_cond=>{:id => q(:library_module_branch,:repo_id)},
       :cols => [:id,:group_id,:repo_name,:local_dir,:remote_repo_name,:remote_repo_namespace]
     },
     {
       :model_name => :repo,
       :alias => :workspace_repo,
       :convert => true,
       :join_type => :inner,
       :join_cond=>{:id => q(:module_branch,:repo_id)},
       :cols => [:id,:group_id,:repo_name,:local_dir]
     }
    ]
  }
}
{
  :schema=>:module,
  :table=>:branch,
  :columns=>{
    :branch => {:type=>:varchar, :size => 50},
    :version => {:type=>:varchar, :size => 50},
    :is_workspace => {:type =>:boolean},
    :type => {:type=>:varchar, :size => 20}, #service_module or component_module
    :current_sha => {:type=>:varchar, :size => 50}, #indicates the sha of the branch that is currently synchronized with object model 
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
    },
    :assembly_id=>{ #non-null if branch for an assembly instance
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    }
  },
  :virtual_columns=>{
    :matching_component_library_branches=> lambda__matching_library_branches.call(:type => :component_module),
    :matching_service_library_branches=> lambda__matching_library_branches.call(:type => :service_module),
    :service_module=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name => :service_module,
         :convert => true,
         :join_type => :inner,
         :join_cond=>{:id => q(:module_branch,:service_id)},
         :cols => [:id,:group_id,:display_name]
       }]
    },
    :parent_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name => :service_module,
         :convert => true,
         :join_type => :left_outer,
         :join_cond=>{:id => q(:module_branch,:service_id)},
         :cols => [:id,:group_id,:display_name]
       },
       {
         :model_name => :component_module,
         :convert => true,
         :join_type => :left_outer,
         :join_cond=>{:id => q(:module_branch,:component_id)},
         :cols => [:id,:group_id,:display_name]
       }]
    },
    :component_module_info =>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name => :repo,
         :convert => true,
         :join_type => :inner,
         :join_cond=>{:id => q(:module_branch,:repo_id)},
         :cols => [:id,:remote_repo_name,:remote_repo_namespace]
       },
       {
         :model_name => :component_module,
         :convert => true,
         :join_type => :inner,
         :join_cond=>{:id => q(:module_branch,:component_id)},
         :cols => [:id,:display_name]
       }]
    },
    #TODO: now that assembly_id is added, can we remove this?
    :assemblies=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name => :component,
         :convert => true,
         :join_type => :inner,
         :join_cond=>{:module_branch_id => q(:module_branch,:id)},
         :filter=>[:eq,:type,"composite"],
         :cols => [:id,:group_id,:display_name]
       }]
    }
  },
  :many_to_one=>[:component_module,:service_module],
  :one_to_many=>[:component_module_ref]
}
