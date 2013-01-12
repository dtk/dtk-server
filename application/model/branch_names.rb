#TODO: putting version defaults in now; may move to seperate file or rename to branch_names_and_versions
module DTK
  VersionFieldDefault = 'master'

  module BranchNamesMixin
    def has_default_version?()
      version = update_object!(:version)[:version]
      version.nil? or  (version == VersionFieldDefault)
    end

    def version_display_name(display_name,version)
      self.class.version_display_name(display_name,version)
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
      (version_field == VersionFieldDefault) ? nil : version_field
    end

    def version_display_name(display_name,version)
      version ? "#{display_name}(#{version})" : display_name
    end

    def library_branch_name(library_idh,version=nil)
      #TODO: when have multiple libraries that can host same module will need to refine
      #      library = library_idh.create_object().update_object!(:ref)
      #     "library-#{library[:ref]}-v#{new_version.to_s}"
      #version ? "v#{version}" : VersionFieldDefault
      version_field(version)
    end

    #MOD_RESTRUCT: TODO: this hard codes in assumption that different users have different repos
    def workspace_branch_name(project,version=nil)
      project.update_object!(:ref)
      version_prefix = ((version and version != VersionFieldDefault)?  "-v#{version}" : "")
      "workspace-#{project[:ref]}#{version_prefix}"
    end
  end
end
