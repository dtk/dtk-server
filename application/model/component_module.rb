module XYZ
  class ComponentModule < Model
    class << self
      def import(library_idh,remote_repo_name)
        local_repo_name = remote_repo_name
        if remote_already_imported?(library_idh,remote_repo_name)
          raise Error.new("Cannot import remote repo (#{remote_repo_name}) which has been imported already")
        end
        if conflict_with_local_repo?(library_idh,local_repo_name)
          raise Error.new("Import conflicts with local repo (#{local_repo_name})")
        end

        #TODO: this might be done a priori
        RepoRemote.authorize_dtk_instance(remote_repo_name)
        #TODO: create repo and implemntations 
        nil
      end

     private
      def remote_already_imported?(library_idh,remote_repo_name)
        ret = nil
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:eq, :remote_repo_name, remote_repo_name]
        }
        repos = Model.get_objs(library_idh.createMH(:repo),sp_hash)
        return ret if repos.empty?
        
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                      [:oneof, :repo_id, repos.map{|r|r[:id]}]]
        }
        impls = Model.get_objs(library_idh.createMH(:implementation),sp_hash)
        not impls.empty?
      end

      def conflict_with_local_repo?(library_idh,local_repo_name)
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                      [:eq, :display_name, local_repo_name]]
        }
        impls = Model.get_objs(library_idh.createMH(:implementation),sp_hash)
        not impls.empty?
      end
    end
  end
end
