module DTK
  class Repo < Model
    r8_nested_require('repo','remote')
    r8_nested_require('repo','diff')
    r8_nested_require('repo','diffs')
    include RemoteMixin

    def self.common_columns()
      [:id,:display_name,:repo_name,:local_dir]
    end

    ###virtual columns
    def base_dir()
      self[:local_dir].gsub(/\/[^\/]+$/,"")
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def get_acesss_rights(repo_user_idh)
      sp_hash = {
        :cols => [:id,:group_id,:access_rights,:repo_usel_id,:repo_id],
        :filter => [:and, [:eq,:repo_id,id()],[:eq,:repo_user_id,repo_user_idh.get_id()]]
      }
      Model.get_obj(model_handle(:repo_user_acl),sp_hash)
    end

    # Method will set self attributes
    # 
    # :remote_repo_name, :remote_repo_namespace
    #
    # From remote repo, this is to minimize changes to existing code base, this should change as we go on forward
    #
    def consume_remote_repo!(remote_repo)
      merge!(:remote_repo_name => remote_repo[:repo_name],:remote_repo_namespace => remote_repo[:repo_namespace])
    end

    def self.create_empty_workspace_repo(project_idh,module_name,module_specific_type,repo_user_acls,opts={})
      #find repo name
      repo_name = private_user_repo_name(module_name,module_specific_type)

      extra_attrs = [:remote_repo_name,:remote_repo_namespace].inject(Hash.new) do |h,k|
        opts[k] ? h.merge(k => opts[k]) : h
      end

      repo_mh = project_idh.createMH(:repo)
      repo_obj = create_repo_obj?(repo_mh,repo_name,extra_attrs)
      repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify_model(repo_idh,repo_user_acls)
      RepoManager.create_empty_workspace_repo(repo_obj,repo_user_acls,opts) 
      repo_obj
    end

    def self.delete(repo_idh)
      repo = repo_idh.create_object()
      RepoManager.delete_repo(repo)
      Model.delete_instance(repo_idh)
    end

   private
    def self.private_user_repo_name(module_name,module_specific_type)
      username = CurrentSession.new.get_username()
      incorporate_module_type(module_specific_type,"#{username}-#{module_name}")

    end
    def self.public_repo_name(module_name,module_specific_type)
      incorporate_module_type(module_specific_type,"public-#{module_name}")
    end

    def self.incorporate_module_type(module_specific_type,repo_name)
      #module_specfic_type can be :service_module, :puppet or :chef
      module_specific_type == :service_module ? "sm-#{repo_name}" : repo_name
    end

    def self.create_repo_obj?(model_handle,repo_name,extra_attrs={})
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:repo_name,repo_name]
      }
      ret = get_obj(model_handle,sp_hash)

      unless ret
        repo_hash = {
          :ref => repo_name,
          :display_name => repo_name,
          :repo_name => repo_name,
          :local_dir =>  "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
        }
        repo_hash.merge!(extra_attrs)

        repo_idh = create_from_row(model_handle,repo_hash)
        ret = repo_idh.create_object().merge(repo_hash)
      end

      # this is only in cases when we import from r8_network 
      if extra_attrs[:remote_repo_name]
        # we extract module name
        module_name = RepoRemote.extract_module_name(extra_attrs[:remote_repo_name])
        # we create repo remote
        RepoRemote.create_repo_remote?(ret.model_handle(:repo_remote), module_name, extra_attrs[:remote_repo_name], extra_attrs[:remote_repo_namespace], ret.id())
      end

      ret
    end

  end
end
