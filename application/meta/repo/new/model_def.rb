{
  :schema=>:repo,
  :table=>:repo,
  :columns=>{
    :repo_name => {:type=>:varchar, :size => 100},
    :local_dir => {:type=>:varchar, :size => 100},
    # TODO: ModuleBranch::Location:  will emove fields :remote_repo_name, :remote_repo_namespace
    :remote_repo_name => {:type=>:varchar, :size => 100}, #non-null if this repo is linked to a remote repo
    :remote_repo_namespace => {:type=>:varchar, :size => 30}  #non-null if this repo is linked to a remote repo
  },
  :virtual_columns=>{
    :base_dir =>{:type => :varchar, :local_dependencies => [:local_dir]}
  },
  :one_to_many => [:repo_user_acl]
}
