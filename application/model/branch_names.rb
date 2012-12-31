#TODO: this changes dpending on mapping to repos and libraries
module DTK
  BranchNameDefaultVersion = 'master'

  module BranchNamesMixin
    def has_default_version?()
      version = update_object!(:version)[:version]
      version.nil? or  (version == BranchNameDefaultVersion)
    end
   protected
    def workspace_branch_name(project)
      self.class.workspace_branch_name(project,self[:version])
    end
  end
  module BranchNamesClassMixin
    def branch_name_default_version()
      BranchNameDefaultVersion
    end

    def library_branch_name(library_idh,version=nil)
      #TODO: when have multiple libraries that can host same module will need to refine
      #      library = library_idh.create_object().update_object!(:ref)
      #     "library-#{library[:ref]}-v#{new_version.to_s}"
      #version ? "v#{version}" : BranchNameDefaultVersion
      version || BranchNameDefaultVersion
    end

    #MOD_RESTRUCT: TODO: this hard codes in assumption that different users have different repos
    def workspace_branch_name(project,version=nil)
      project.update_object!(:ref)
      version_prefix = ((version and version != BranchNameDefaultVersion)?  "-v#{version}" : "")
      "workspace-#{project[:ref]}#{version_prefix}"
    end
  end
end
