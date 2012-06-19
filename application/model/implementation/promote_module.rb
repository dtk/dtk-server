module DTK
  module ImplPromoteModuleMixin
=begin
    def promote_workspace_to_library(new_version,library_idh)
      #iterate over components to see which ones changed; think need component to point to implenntation
      #TODO: can make more efficient by reducing number of seprate calss to db
      update_object!(:component_type,:extended_base,:implementation_id)
      #check if version exists already
      raise Error.new("component template #{self[:component_type]} (#{new_version}) already exists") if  matching_library_template_exists?(new_version,library_idh)

      #if project template has  been updated then need to generate
      proj_impl = id_handle(:model_name => :implementation, :id => self[:implementation_id]).create_object

      library_impl_idh = proj_impl.clone_into_library_if_needed(library_idh,new_version)

      override_attrs = {:version => new_version, :implementation_id => library_impl_idh.get_id()}
      library_idh.create_object().clone_into(self,override_attrs)
    end

   private

    def matching_library_template_exists?(version,library_idh)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                     [:eq, :library_library_id, library_idh.get_id()],
                     [:eq, :version, version],
                     [:eq, :component_type, self[:component_type]]]
      }
      Model.get_objects_from_sp_hash(model_handle,sp_hash).first
    end


    #self is a project implementation; returns library implementation idh
    def clone_into_library_if_needed(library_idh,new_version)
      ret = nil
      #if implementation is updated, need to create a new implemntation in library; otherwise use
      update_object!(:updated,:repo,:branch)
      if self[:updated]
        new_branch = library_branch_name(new_version,library_idh)
        #TODO: assuming that implementaion files do not hvae any content that is not written to repo
        RepoManager.clone_branch(new_branch,{:implementation => self})
        override_attrs={:version => new_version,:branch => new_branch}
        new_impl_id = library_idh.create_object.clone_into(self,override_attrs)
        ret = id_handle(:model_name => :implemntation, :id => new_impl_id)
      else
        impl_obj = matching_library_template_exists?(self[:version],library_idh)
        raise Error.new("expected to find a matching library implemntation") unless impl_obj
        ret = impl_obj.id_handle
      end
      ret
    end

    #self is a project implementation
    def replace_library_impl_with_proj_impl()
      impl_objs_info = get_objs(:cols=>[:linked_library_implementation,:repo,:branch]).first
      raise Error.new("Cannot find associated library implementation") unless impl_objs_info
      library_impl = impl_objs_info[:library_implementation]
      project_impl = impl_objs_info
      RepoManager.merge_from_branch(project_impl[:branch],{:implementation => library_impl})
      RepoManager.push_implementation(:implementation => library_impl)
    end
=end
  end
end
