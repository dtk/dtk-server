module DTK
  module ImplBranchNamesMixin
   protected
    def workspace_branch_name(project)
      project.update_object!(:ref)
      update_object!(:version,:repo) #TODO: do we need :repo?
      version_info = (has_default_version?() ? "" : "-v#{self[:version]}")
      "workspace-#{project[:ref]}#{version_info}"
    end

    def library_branch_name(new_version,library_idh)
      library = library_idh.create_object().update_object!(:ref)
      "library-#{library[:ref]}-v#{new_version.to_s}"
    end
  end
end
