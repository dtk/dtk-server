module DTK
  module BranchNamesMixin
   protected
    def workspace_branch_name(project)
      project.update_object!(:ref)
      version_info = (has_default_version?() ? "" : "-v#{self[:version]}")
      "workspace-#{project[:ref]}#{version_info}"
    end

    def library_branch_name(new_version,library_idh)
      library = library_idh.create_object().update_object!(:ref)
      "library-#{library[:ref]}-v#{new_version.to_s}"
    end
   private
    DefaultVersion = 'master'
    def has_default_version?()
      update_object!(:version)[:version] == DefaultVersion
    end

  end
end
