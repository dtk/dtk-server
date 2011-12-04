{
  :schema=>:repo,
  :table=>:repo,
  :columns=>{
    :repo_name => {:type=>:varchar, :size => 100},
    :local_dir => {:type=>:varchar, :size => 100}
  },
  :virtual_columns=>{
    :base_dir =>{:type => :varchar, :local_dependencies => [:local_dir]}
  },
  :one_to_many => [:repo_user_acl]
}
