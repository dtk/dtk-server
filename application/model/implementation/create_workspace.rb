module DTK
  module ImplCreateWorkspaceMixin
    def clone_into_project_if_needed(project)
      proj_idh = project.id_handle()
      #check if there is a matching implementation aready in the project
      # match looks for match on rep and version
      base_sp_hash = {
        :model_name => :implementation,
        :filter => [:eq, :id, id()],
        :cols => [:repo, :version, :branch]
      }
      join_array = 
        [{
           :model_name => :implementation,
           :alias => :proj_impl,
           :convert => true,
           :join_type => :left_outer,
           :filter => [:eq, :project_project_id, proj_idh.get_id()],
           :join_cond => {:repo => :implementation__repo, :version => :implementation__version},
           :cols => [:id,:repo,:version]
         }]

      augmented_impl = Model.get_objects_from_join_array(model_handle(),base_sp_hash,join_array).first
      raise Error.new("No implementation for component") unless augmented_impl
      #return matching implementation idh if there is a match
      return augmented_impl[:proj_impl].id_handle() if augmented_impl[:proj_impl]

      #if reach here; no match and need to clone
      new_branch = augmented_impl.workspace_branch_name(project)
      RepoManager.clone_branch(new_branch,{:implementation => augmented_impl})
      override_attrs={:branch => new_branch}
      new_impl_id = project.clone_into(self,override_attrs)
      id_handle(:id => new_impl_id, :model => :implementation)
    end
  end
end
