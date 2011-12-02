module XYZ
  class Repo 
    #### for interacting with existing repos
    def self.get_file_content(file_asset,context)
      get_repo(context).get_file_content(file_asset)
    end

    def self.update_file_content(file_asset,content,context)
      get_repo(context).update_file_content(file_asset,content)
    end

    def self.add_file(file_asset,content,context)
      get_repo(context).add_file(file_asset,content)
    end

    def self.push_implementation(context)
      get_repo(context).push_implementation()
    end

    def self.clone_branch(context,new_branch)
      get_repo(context).clone_branch(new_branch)
    end

    def self.merge_from_branch(context,branch_to_merge_from)
      get_repo(context).merge_from_branch(branch_to_merge_from)
    end

    def self.delete_branch(context)
      get_repo(context).delete_branch()
    end

    def self.delete_all_branches(model_handle)
      repo_names = get_all_repo_names()
      delete_branches(model_handle,*repo_names)
    end
    def self.delete_branches(model_handle,*repo_names)
      klass = load_and_return_adapter_class()
      repo_names.each do |repo_name|
        #TODO: change so this from RepoMeta if want to put in hooks for per branch auth
        klass.get_branches(repo_name).each do |branch|
          next if branch == "master"
          pp "deleting branch (#{branch}) in repo (#{repo_name})"
          context = {
            :implementation => {
            :repo => repo_name,
            :branch => branch
            }
          }
          get_repo(context).delete_branch()
        end
      end
    end

    ###### for creating and deleting repositories
    def self.test_pp_config(model_handle,repo_name)
      klass = load_and_return_adapter_class()
      users = %w{root remote-server r8server r8client} 
      repo_user_acls = users.map{|u|{:access_rights => "RW+", :user_name => u}}
      hash_values = {
        :config_agent_type => "puppet",
        :repo_name => repo_name,
        :repo_user_acls => repo_user_acls
      }
      create_repo?(model_handle,hash_values)
    end

    def self.create_repo?(model_handle,hash_values)
      klass = load_and_return_adapter_class()
      actual_repo_name = klass.actual_repo_name(hash_values)
      return if get_all_repo_names(model_handle).include?(actual_repo_name) 
      create_repo(model_handle,hash_values,actual_repo_name,klass)
    end
    def self.create_repo(model_handle,hash_values,actual_repo_name=nil,klass=nil)
      klass ||= load_and_return_adapter_class()
      actual_repo_name ||= klass.actual_repo_name(hash_values)
      augmented_hash_values = {:actual_repo_name => actual_repo_name}.merge(hash_values)
      repo_obj = Model.create_stub(model_handle,augmented_hash_values)
      klass.create_empty_repo(repo_obj)
      repo_obj.save!()
    end

    def self.get_repo(context)
      #TODO: do we still need __top
      repo = (context[:implementation]||{})[:repo]||"__top"
      branch = (context[:implementation]||{})[:branch]
      raise Error.new("cannot find branch in context") unless branch
      CachedRepoObjects[repo] ||= Hash.new
      CachedRepoObjects[repo][branch] ||= load_and_create(repo,branch)
    end
   private
    CachedRepoObjects = Hash.new

    def self.load_and_return_adapter_class()
      return @cached_adpater_class if @cached_adpater_class
      adapter_name = (R8::Config[:repo]||{})[:type]
      raise Error.new("No repo adapter specified") unless adapter_name
      @cached_adpater_class = DynamicLoader.load_and_return_adapter_class("repo",adapter_name)
    end

    def self.load_and_create(path,branch)
      klass = load_and_return_adapter_class() 
      klass.create(path,branch)
    end

    def self.get_all_repo_names(model_handle)
      RepoMeta.get_all_repo_names(model_handle)
    end
  end
end
