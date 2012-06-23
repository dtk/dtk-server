module XYZ
  class ComponentModule
    class << self
      def import(library_idh,remote_repo_name)
        if remote_already_imported?(library_idh,remote_repo_name)
          raise Error.new("Cannot import remote repo (#{remote_repo_name}) which has been imported already")
        end
        #TODO: this might be done a priori
        RepoRemote.authorize_dtk_instance(remote_repo_name)
        #TODO: create repo and implemntations 
        nil
      end

     private
      def remote_already_imported?(library_idh,remote_repo_name)
        remotes_already_imported(library_idh,remote_repo_name)[remote_repo_name]
      end
      #returns hash with key for every name imported and value being the idh(s) associated with it
      def remotes_already_imported(library_idh,remote_repo_name)
        ret = Hash.new
        remote_repo_names = [remote_repo_names] unless remote_repo_names.kind_of?(Array)
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:oneof, :remote_repo_name, remote_repo_names]
        }
        remote_repo_clones = Model.get_objs(library_idh.createMH(:repo),sp_hash)
        return ret if remote_repo_clones.empty?
        
        sp_hash = {
          :cols => [:id,:display_name,:remote_repo_id],
          :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                      [:oneof, :repo_id, remote_repo_clones.map{|r|r[:id]}]]
        }
        impls = Model.get_objects(library_idh.createMH(:implementation),sp_hash)
        return ret if impls.empty?
        ndx_clone_names = remote_repo_clones.inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:display_name])
        end
        impls.each do |r|
          (ret[ndx_clone_names[r[:repo_id]]] ||= Array.new) << r.id_handle()
        end
        ret
      end
    end
  end
end
