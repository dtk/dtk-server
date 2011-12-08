require 'fileutils'
module XYZ
  class RepoManager 
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

    def self.add_all_files(context)
      get_repo(context).add_all_files()
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
        #TODO: change so this from Repo if want to put in hooks for per branch auth
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
    #TODO: need to change or prtect since with this design pattern get stack error if adapter does not have this defined
    def self.repo_url()
      klass = load_and_return_adapter_class()
      klass.repo_url()
    end
    def self.repo_name(username,config_agent_type,module_name)
      klass = load_and_return_adapter_class()
      klass.repo_name(username,config_agent_type,module_name)
    end

    def self.create_repo(repo_obj,repo_user_acls,opts={})
      klass = load_and_return_adapter_class()
      #create repo on repo server
      klass.create_server_repo(repo_obj,repo_user_acls,opts)
      #create on r8 a local repo (pointing to git server)
      klass.create_local_repo(repo_obj,opts)
    end

    def self.delete_all_repos()
      klass = load_and_return_adapter_class()
      #delete all repos on repo server
      klass.delete_all_server_repos()
      delete_all_local_repos()
    end

    def self.delete_all_local_repos()
      repo_base_dir = R8::Config[:repo][:base_directory]
      if File.directory?(repo_base_dir)
        Dir.chdir(R8::Config[:repo][:base_directory]) do
          Dir["*"].each{|local_repo_dir|FileUtils.rm_rf local_repo_dir} 
        end
      end
    end
    ##########
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
      @cached_adpater_class = DynamicLoader.load_and_return_adapter_class("repo_manager",adapter_name)
    end

    def self.load_and_create(path,branch)
      klass = load_and_return_adapter_class() 
      klass.create(path,branch)
    end

    def self.get_all_repo_names(model_handle)
      Repo.get_all_repo_names(model_handle)
    end
  end
end
