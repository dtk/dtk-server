#TODO: deprecate when get all this logic in ModuleLocation::Target
#TODO: putting version defaults in now; may move to seperate file or rename to branch_names_and_versions
module DTK
  VersionFieldDefault = 'master'

  module BranchNamesMixin
    def has_default_version?()
      version = update_object!(:version)[:version]
      version.nil? or  (version == VersionFieldDefault)
    end

   protected
    def workspace_branch_name(project)
      self.class.workspace_branch_name(project,self[:version])
    end
  end
  module BranchNamesClassMixin
    def version_field_default()
      VersionFieldDefault
    end

    def version_field(version)
      version || VersionFieldDefault
    end

    def version_from_version_field(version_field)
      unless version_field == VersionFieldDefault
        ModuleVersion.ret(version_field)
      end
    end

    #TODO: deprecate
    def library_branch_name(library_idh,version=nil)
      #TODO: when have multiple libraries that can host same module will need to refine
      #      library = library_idh.create_object().update_object!(:ref)
      #     "library-#{library[:ref]}-v#{new_version.to_s}"
      #version ? "v#{version}" : VersionFieldDefault
      version_field(version)
    end

    #MOD_RESTRUCT: TODO: this hard codes in assumption that different users have different repos
    def workspace_branch_name(project,version=nil)
      user_prefix = "workspace-#{project.get_field?(:ref)}"
      if version.kind_of?(ModuleVersion::AssemblyModule)
        assembly_suffix = "--assembly-#{version.assembly_name}"
        "#{user_prefix}#{assembly_suffix}"
      else
        version_suffix = ((version and version != VersionFieldDefault)?  "-v#{version}" : "")
        "#{user_prefix}#{version_suffix}"
      end
    end
  end
end
