module DTK
  class RepoRemote < Model
    def print_form(opts=Opts.new)
      ret = self[:display_name]||'' #'' just to be safe
      ret = "#{DTKNCatalogPrefix}#{ret}" if opts[:dtkn_prefix]
      ret = "#{DefaultMarker}#{ret}" if opts[:is_default_namespace]
      ret
    end
    DTKNCatalogPrefix = 'dtkn://'
    DefaultMarker = '*'

    def self.create_repo_remote(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id,opts=Opts.new)
      is_default = 
        if opts[:set_as_default]
          true
        elsif opts[:set_as_default_if_first]
          get_matching_remote_repos(repo_remote_mh,repo_id, module_name).size == 0
        else
          false
        end
      remote_repo_create_hash = { 
        :repo_name => repo_name, 
        :display_name => "#{repo_namespace}/#{module_name}", 
        :repo_namespace => repo_namespace, 
        :repo_id => repo_id, 
        :ref => module_name,
        :is_default => is_default
      }
      create_from_row(repo_remote_mh,remote_repo_create_hash)
    end

    def self.delete_repos(idh_list)
      delete_instances(idh_list)
    end

    def self.get_remote_repo(repo_remote_mh,repo_id, module_name, repo_namespace)
      matches = get_matching_remote_repos(repo_remote_mh,repo_id, module_name, repo_namespace)
      if matches.size > 1
        raise Error.new("Unexpected to have multiple matches in get_remote_repo (#{matches.map{|r|r[:display_name]}.join(',')})")
      else
        matches.first
      end
    end
    def self.get_matching_remote_repos(repo_remote_mh,repo_id, module_name, repo_namespace=nil)
      sp_hash = {
        :cols   => [:id], 
        :filter =>  
          [:and,
           [:eq, :repo_id, repo_id],
           repo_namespace && [:eq, :repo_namespace, repo_namespace], 
           [:eq, :ref, module_name]
          ].compact
      }
      get_objs(repo_remote_mh, sp_hash)
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

    def self.ret_default_remote_repo(repo_remotes)
      #Making robust in case multiple ones marked default
      pruned = repo_remotes.select{|r|r.get_field?(:is_default)}
      if pruned.empty?
        compute_default_remote_repo(repo_remotes)
      elsif pruned.size == 1
        pruned.first
      else
        Log.error("Multiple default remotes found (#{pruned.map{|r|r[:display_name]}.join('')})")
        compute_default_remote_repo(pruned)
      end
    end

   private
    #TODO: deprecate once all data is migrated so :is_default is marked
    def self.compute_default_remote_repo(repo_remotes)
      Log.info("Calling compute_default_remote_repo on (#{repo_remotes.map{|r|r.get_field?(:display_name)}.join(',')})")
      unless (repo_remotes||[]).empty?
        #TODO: enhance so that default is one taht matche's user's default namespace
        #set on augmented_module_branch[:repo] fields associated with the default namespace
        # we sort descending by created date
        # default is the one which is the oldest
        repo_remotes.each{|r|r.update_object!(:created_at)}
        default_repo_remote = repo_remotes.sort {|a,b| a[:created_at] <=>  b[:created_at]}.first
        default_repo_remote.update(:is_default => true) #migrate it
        default_repo_remote
      end
    end

  end
end
