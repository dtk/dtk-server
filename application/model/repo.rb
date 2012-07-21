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

    def get_acesss_rights(repo_user_idh)
      sp_hash = {
        :cols => [:id,:group_id,:access_rights,:repo_usel_id,:repo_id],
        :filter => [:and, [:eq,:repo_id,id()],[:eq,:repo_user_id,repo_user_idh.get_id()]]
      }
      Model.get_obj(model_handle(:repo_user_acl),sp_hash)
    end

    def self.create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,repo_user_acls,opts={})
      #find repo name
      public_lib = Library.get_public_library(library_idh.createMH())
      if (public_lib && public_lib[:id]) == library_idh.get_id()
        repo_name = public_repo_name(module_name,module_specific_type)
      else
        repo_name = private_user_repo_name(module_name,module_specific_type)
      end 

      extra_attrs = Hash.new
      if opts[:remote_repo_name]
        extra_attrs.merge!(:remote_repo_name => opts[:remote_repo_name])
      end

      repo_mh = library_idh.createMH(:repo)
      repo_obj = create_repo_obj?(repo_mh,repo_name,extra_attrs)
      repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify_model(repo_idh,repo_user_acls)
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
      unless self[:remote_repo_name]
        raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
      end
      remote_url = Remote.repo_url_ssh_access(self[:remote_repo_name])
      remote_name = remote_name_for_push_pull()
      RepoManager.synchronize_with_remote_repo(self[:repo_name],remote_name,remote_url)
    end

    def push_to_remote(remote_repo_name=nil)
      update_cols = [:repo_name] + (remote_repo_name ? [] : [:remote_repo_name])
      update_object!(*update_cols)
      remote_repo_name ||= self[:remote_repo_name]
      unless remote_repo_name
        raise ErrorUsage.new("Cannot push to remote repo if local repo not linked")
      end
      remote_name = remote_name_for_push_pull()
      RepoManager.push_to_remote_repo(self[:repo_name],remote_name)
    end

    def link_to_remote(remote_repo_name)
      update_object!(:repo_name)
      remote_url = Remote.repo_url_ssh_access(remote_repo_name)
      remote_name = remote_name_for_push_pull()
      RepoManager.link_to_remote_repo(self[:repo_name],remote_name,remote_url)
      remote_repo_name
    end

   private    

    def remote_name_for_push_pull()
      "remote"
    end

    def self.private_user_repo_name(module_name,module_specific_type)
      username = CurrentSession.get_username()
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
