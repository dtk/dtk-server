#TODO: this changes dpending on mapping to repos and libraries
module DTK
  BranchNameDefaultVersion = 'master'

  module BranchNamesMixin
   protected
    def workspace_branch_name(project)
      self.class.workspace_branch_name(project,self[:version])
    end

   private
    def has_default_version?()
      version = update_object!(:version)[:version]
      version.nil? or  (version == BranchNameDefaultVersion)
    end
  end
  module BranchNamesClassMixin
    def library_branch_name(library_idh,version=nil)
      #TODO: when have multiple libraries that can host same module will need to refine
      #      library = library_idh.create_object().update_object!(:ref)
      #     "library-#{library[:ref]}-v#{new_version.to_s}"
      #version ? "v#{version}" : BranchNameDefaultVersion
      version || BranchNameDefaultVersion
    end

    def workspace_branch_name(project,version=nil)
      project.update_object!(:ref)
      version_info = (version ? "" : "-v#{version}")
      "workspace-#{project[:ref]}#{version_info}"
    end
  end
end
