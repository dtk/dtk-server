module DTK
  module ImplRemoteClassMixin
    def import_remote(impl_mh,remote_repo_name,library_idh)
      if remote_already_imported?(impl_mh,library_idh,remote_repo_name)
        raise Error.new("Cannot import remote repo (#{remote_repo_name}) which has been imported already")
      end
      #TODO: this should be done a priori
      RepoRemote.authorize_dtk_instance(remote_repo_name)
    end

   private
    def remote_already_imported?(impl_mh,library_idh,remote_repo_name)
      remotes_already_imported(impl_mh,library_idh,remote_repo_name)[remote_repo_name]
    end
    #returns hash with key for every name imported and value being the idh(s) associated with it
    def remotes_already_imported(impl_mh,library_idh,remote_repo_names)
      ret = Hash.new
      remote_repo_names = [remote_repo_names] unless remote_repo_names.kind_of?(Array)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:oneof, :remote_repo_name, remote_repo_names]
      }
      remote_repo_clones = get_objs(impl_mh.createMH(:repo),sp_hash)
      return ret if remote_repo_clones.empty?

      sp_hash = {
        :cols => [:id,:display_name,:remote_repo_id],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:oneof, :remote_repo_id, remote_repo_clones.map{|r|r[:id]}]]
      }
      impls = get_objects(impl_mh,sp_hash)
      return ret if impls.empty?
      ndx_clone_names = remote_repo_clones.inject(Hash.new) do |h,r|
        h.merge(r[:id] => r[:display_name])
      end
      impls.each do |r|
        (ret[ndx_clone_names[r[:remote_repo_id]]] ||= Array.new) << r.id_handle()
      end
      ret
    end
  end
end
