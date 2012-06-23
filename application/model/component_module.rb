module XYZ
  class ComponentModule < Model
    def self.import(library_idh,remote_repo_name)
      local_repo_name = remote_repo_name
      if remote_already_imported?(library_idh,remote_repo_name)
        raise Error.new("Cannot import remote repo (#{remote_repo_name}) which has been imported already")
      end
      if conflict_with_local_repo?(library_idh,local_repo_name)
        raise Error.new("Import conflicts with local repo (#{local_repo_name})")
      end

      #TODO: this might be done a priori
      RepoRemote.authorize_dtk_instance(remote_repo_name)
      #create empty repo on local repo manager; add a remote to teh remote repo and do a pull from teh remote
      #TODO: create repo and implemntations 
      nil
    end

    private
    def self.remote_already_imported?(library_idh,remote_repo_name)
      ret = nil
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :remote_repo, remote_repo_name]]
      }
      cms = get_objs(library_idh.createMH(:component_module),sp_hash)
      not cms.empty?
    end

    def self.conflict_with_local_repo?(library_idh,local_repo_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :display_name, local_repo_name]]
      }
      cms = get_objs(library_idh.createMH(:component_module),sp_hash)
      not cms.empty?
    end
  end
end
