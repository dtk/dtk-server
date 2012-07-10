module XYZ
  class Repo < Model
    r8_nested_require('repo','remote')
    r8_nested_require('repo','diff')
    r8_nested_require('repo','diffs')

    ###virtual columns
    def base_dir()
      self[:local_dir].gsub(/\/[^\/]+$/,"")
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,repo_user_acls,module_type,opts={})
      #find repo name
      public_lib = Library.get_public_library(library_idh.createMH())
      if (public_lib && public_lib[:id]) == library_idh.get_id()
        repo_name = public_repo_name(config_agent_type,module_name,module_type)
      else
        repo_name = private_user_repo_name(config_agent_type,module_name,module_type)
      end 

      extra_attrs = Hash.new
      if opts[:remote_repo_name]
        extra_attrs.merge!(:remote_repo_name => opts[:remote_repo_name])
      end

      repo_mh = library_idh.createMH(:repo)
      repo_obj = create_repo_obj?(repo_mh,repo_name,extra_attrs)
      repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify(repo_idh,repo_user_acls)
      RepoManager.create_repo_and_local_clone(repo_obj,repo_user_acls,opts) 
      repo_obj
    end

    def self.delete(repo_idh)
      repo = repo_idh.create_object()
      RepoManager.delete_repo(repo)
      Model.delete_instance(repo_idh)
    end

    def synchronize_with_remote_repo()
      update_object!(:repo_name,:remote_repo_name)
      remote_url = Remote.repo_url_ssh_access(self[:remote_repo_name])
      remote_name = "remote"
      RepoManager.synchronize_with_remote_repo(self[:repo_name],remote_name,remote_url)
    end

    def link_to_remote(remote_module_name)
      self[:remote_module_name] = remote_module_name
    end

   private    

    def self.private_user_repo_name(config_agent_type,module_name,module_type)
      username = CurrentSession.get_username()
      #incorporate_module_type(module_type,"#{username}-#{config_agent_type}-#{module_name}"
      incorporate_module_type(module_type,"#{username}-#{module_name}")

    end
    def self.public_repo_name(config_agent_type,module_name,module_type)
      #incorporate_module_type(module_type,"public-#{config_agent_type}-#{module_name}")
      incorporate_module_type(module_type,"public-#{module_name}")
    end

    def self.incorporate_module_type(module_type,repo_name)
      module_type == :service_module ? "sm-#{repo_name}" : repo_name
    end

    def self.create_repo_obj?(model_handle,repo_name,extra_attrs={})
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:repo_name,repo_name]
      }
      ret = get_obj(model_handle,sp_hash)
      return ret if ret 

      repo_hash = {
        :ref => repo_name,
        :display_name => repo_name,
        :repo_name => repo_name,
        :local_dir =>  "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
      }
      repo_hash.merge!(extra_attrs)

      repo_idh = create_from_row(model_handle,repo_hash)
      repo_id = repo_idh.get_id()
      repo_idh.create_object().merge(repo_hash)
    end

    def self.common_columns()
      [:id,:display_name,:repo_name,:local_dir]
    end
  end
end
