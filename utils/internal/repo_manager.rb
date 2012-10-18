require 'fileutils'
module XYZ
  class RepoManager 
    class << self
      #admin and repo methods that just pass to lower level object or class
      RepoMethods = [:add_all_files,:push_implementation,:add_branch,:add_branch?,:add_branch_and_push_to_origin?,:merge_from_branch,:delete_branch,:add_remote,:pull_changes,:diff,:ls_r,:fast_foward_merge_from_branch,:fetch_all,:rebase_from_remote,:diff,:fast_foward_pull]
      AdminMethods = [:list_repos,:repo_url,:repo_server_dns,:repo_server_ssh_rsa_fingerprint,:repo_name,:set_user_rights_in_repos,:remove_user_rights_in_repos,:add_user,:delete_user]

      def method_missing(name,*args,&block)
        if RepoMethods.include?(name)
          context = args.pop
          return get_adapter_repo(context).send(name,*args,&block)
        end
        if klass = class_if_admin_method?(name) 
          return klass.send(name,*args,&block)
        end
        super
      end
      def respond_to?(name)
        !!(defined_method?(name) || super)
      end

      def get_file_content(file_obj_or_path,context)
        file_obj_or_path = {:path => file_obj_or_path} if file_obj_or_path.kind_of?(String)
        get_adapter_repo(context).get_file_content(file_obj_or_path)
      end

      #signature is effectively def add_file(file_obj_or_path,content,commit_msg=nil,context)
      def add_file(*args)
        context = args.pop
        file_obj_or_path,content,commit_msg = args
        file_obj_or_path = {:path => file_obj_or_path} if file_obj_or_path.kind_of?(String)
        get_adapter_repo(context).add_file(file_obj_or_path,content,commit_msg)
      end
      def update_file_content(file_obj_or_path,content,context)
        file_obj_or_path = {:path => file_obj_or_path} if file_obj_or_path.kind_of?(String)
        get_adapter_repo(context).update_file_content(file_obj_or_path,content)
      end
      
     private
      def defined_method?(name)
        RepoMethods.include?(name) or !!class_if_admin_method?(name)
      end
      def class_if_admin_method?(name)
        load_and_return_adapter_class() if AdminMethods.include?(name)
      end
    end

    #### for interacting with particular repo
    def self.delete_all_branches(repo_mh)
      repo_names = get_all_repo_names(repo_mh)
      delete_branches(*repo_names)
    end
    def self.delete_branches(*repo_names)
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
          get_adapter_repo(context).delete_branch()
        end
      end
    end

    ### for dealing with actual repos
    class << self
      def synchronize_with_remote_repo(repo_name,branch,remote_name,remote_url,opts={})
        adapter_repo = get_adapter_repo(context(repo_name,branch))      
        adapter_repo.synchronize_with_remote_repo(remote_name,remote_url,opts)
      end

      #returns :equal, :local_behind, :local_ahead, or :branchpoint 
      def ret_remote_merge_relationship(repo_name,branch,remote_name,opts={})
        adapter_repo = get_adapter_repo(context(repo_name,branch))      
        adapter_repo.ret_merge_relationship(:remote_branch,"#{remote_name}/#{branch}",opts)
      end

      def push_to_remote_repo(repo_name,branch,remote_name)
        adapter_repo = get_adapter_repo(context(repo_name,branch))      
        adapter_repo.push_changes(remote_name)
        repo_name
      end

      def link_to_remote_repo(repo_name,branch,remote_name,remote_url)
        adapter_repo = get_adapter_repo(context(repo_name,branch))      
        adapter_repo.add_or_update_remote(remote_name,remote_url)
        repo_name
      end

      def unlink_remote(repo_name,remote_name)
        adapter_repo = get_adapter_repo(context(repo_name,"master"))
        adapter_repo.remove_remote?(remote_name)
      end

     private
      def context(repo_name,branch)
        {:implementation => {:repo => repo_name, :branch => branch}}
      end
    end

    ###### for repo admin functions, such as creating and deleting repositories

    def self.create_repo_and_local_clone(repo_obj,repo_user_acls,opts={})
      klass = load_and_return_adapter_class()
      #create repo on repo server
      klass.create_server_repo(repo_obj,repo_user_acls,opts)
      klass.create_repo_clone(repo_obj,opts)
    end

    def self.delete_all_repos()
      klass = load_and_return_adapter_class()
      #delete all repos on repo server
      klass.delete_all_server_repos()
      delete_all_local_repos()
    end

    def self.delete_repo(repo)
      klass = load_and_return_adapter_class()
      repo.update_object!(:repo_name,:local_dir)
      klass.delete_server_repo(repo[:repo_name])
      delete_local_repo(repo[:local_dir])
    end

    class << self
      def delete_local_repo(repo_local_dir)
        FileUtils.rm_rf repo_local_dir if File.directory?(repo_local_dir)
      end
      def delete_all_local_repos()
        repo_base_dir = R8::Config[:repo][:base_directory]
        if File.directory?(repo_base_dir)
          Dir.chdir(R8::Config[:repo][:base_directory]) do
            Dir["*"].each{|local_repo_dir|FileUtils.rm_rf local_repo_dir} 
          end
        end
      end
      private :delete_local_repo,:delete_all_local_repos
    end
    
    ##########
    def self.get_adapter_repo(context)
      repo_dir,branch = ret_repo_dir_and_branch(context)
      raise Error.new("cannot find branch in context") unless branch
      CachedRepoObjects[repo_dir] ||= Hash.new
      CachedRepoObjects[repo_dir][branch] ||= load_and_create(repo_dir,branch)
    end

   private
    CachedRepoObjects = Hash.new
    def self.ret_repo_dir_and_branch(context)
      repo_dir = branch = nil
      if context.kind_of?(ModuleBranch)
        repo_dir,branch = context.repo_and_branch()
      elsif context.kind_of?(Repo)
        context.update_object!(:repo_name)
        repo_dir = context[:repo_name]
        branch = "master"
      elsif context.kind_of?(Implementation)
        context.update_object!(:repo,:branch)
        repo_dir = context[:repo]
        branch = context[:branch]
      elsif context.kind_of?(Hash) and context[:repo_dir] and context[:branch]
        repo_dir = context[:repo_dir]
        branch = context[:branch]
      else
        #TODO: deprecate after replace use of this pattern
        #assume that it has hash with :implementation key
        #TODO: do we still need __top
        repo_dir = (context[:implementation]||{})[:repo]||"__top"
        branch = (context[:implementation]||{})[:branch]
      end
      [repo_dir,branch]
    end

    def self.load_and_return_adapter_class()
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = (R8::Config[:repo]||{})[:type]
      raise Error.new("No repo adapter specified") unless adapter_name
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class("repo_manager",adapter_name)
    end

    def self.load_and_create(repo_dir,branch)
      klass = load_and_return_adapter_class() 
      klass.create(repo_dir,branch)
    end

    def self.get_all_repo_names(model_handle)
      Repo.get_all_repo_names(model_handle)
    end
  end

  class RemoteRepoManager < RepoManager 
    def self.load_and_return_adapter_class()
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = "remote_repo"
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class("repo_manager",adapter_name)
    end
  end
end
