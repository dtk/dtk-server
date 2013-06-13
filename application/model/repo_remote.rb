module DTK
  class RepoRemote < Model
    def print_form(opts=Opts.new)
      ret = self[:display_name]
      ret = "*#{ret}" if opts[:is_default_namespace]
      ret
    end

    def self.create_repo_remote(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id)
      remote_repo_create_hash = { 
        :repo_name => repo_name, 
        :display_name => "#{repo_namespace}/#{module_name}", 
        :repo_namespace => repo_namespace, 
        :repo_id => repo_id, 
        :ref => module_name
      }
      #repo_remote_id = create_from_row(repo_remote_mh,remote_repo_create_hash, {}).get_id()
      return create_from_row(repo_remote_mh,remote_repo_create_hash)
    end

    def self.delete_repos(idh_list)
      delete_instances(idh_list)
    end

    def self.get_remote_repo(repo_remote_mh,repo_id, module_name, repo_namespace)
      sp_hash = {
        :cols   => [:id], 
        :filter =>  [:and, 
                      [:eq, :repo_id, repo_id],
                      [:eq, :repo_namespace, repo_namespace], 
                      [:eq, :ref, module_name]
                    ] 
      }
      
      get_obj(repo_remote_mh, sp_hash)
    end

    def self.extract_module_name(repo_name)
      repo_name.split(/\-\-.{2}\-\-/).last
    end

    def self.create_repo_remote?(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id)
      repo_remote = get_remote_repo(repo_remote_mh, repo_id, module_name, repo_namespace)
      unless repo_remote
        repo_remote = create_repo_remote(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id)
      end
      repo_remote
    end

    def self.ret_default_remote_repo(repo,repo_remotes)
      #TODO: stub until get more sophistiacted strategy for setting the default namespace
      #passing in repo in case we use it later
      unless (repo_remotes||[]).empty?
        #set on augmented_module_branch[:repo] fields associated with the default namespace
        # we sort descending by created date
        # default is the one which is the oldest
        repo_remotes.each{|r|r.update_object!(:created_at)}
        repo_remotes.sort {|a,b| a[:created_at] <=>  b[:created_at]}.first
      end
    end

  end
end
