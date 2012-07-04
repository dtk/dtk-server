module DTK
  module ImplPromoteModuleMixin
    #self is a project implementation; returns library implementation idh
    def promote_module_to_new_version(new_version,library_idh)
      ret = nil
      library_impl_idh = proj_impl.clone_impl_into_library_if_needed(new_version,library_idh)
      if library_impl_idh
        override_attrs = {:version => new_version, :implementation_id => library_impl_idh.get_id()}
        cmps = get_objs({:cols => [:component_summary_info]}).map{|r|r[:component]}
        library =  library_idh.create_object()
        cmps.each{|cmp|library.clone_into(cmp,override_attrs)}

        ret = library_impl_idh
      end
      ret
    end

   private
    def matching_library_template_exists?(version,library_idh)
      update_object!(:repo)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                     [:eq, :library_library_id, library_idh.get_id()],
                     [:eq, :version, version],
                     [:eq, :repo, self[:repo]]]
      }
      Model.get_obj(model_handle,sp_hash)
    end

    def clone_impl_into_library(new_version,library_idh)
      ret = nil
      update_object!(:updated,:repo,:branch)
      if matching_library_template_exists?(self[:version],library_idh)
        raise Error.new("Version (#{self[:version]}) exists in library already")
      end
      if self[:updated]
        new_branch = library_branch_name(library_idh,new_version)
        #TODO: assuming that implementaion files do not hvae any content that is not written to repo
        RepoManager.clone_branch(new_branch,{:implementation => self})
        override_attrs={:version => new_version,:branch => new_branch}
        new_impl_id = library_idh.create_object.clone_into(self,override_attrs)
        ret = id_handle(:model_name => :implemntation, :id => new_impl_id)
      else
        Log.info("nothing updated so no op")
      end
      ret
    end
  end
end
