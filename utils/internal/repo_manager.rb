require 'fileutils'
module XYZ
  class RepoManager 
    class << self
      #admin and repo methods that just pass to lower level object or class
      RepoMethods = [:get_file_content,:update_file_content,:add_file,:add_all_files,:push_implementation,:clone_branch,:merge_from_branch,:delete_branch,:add_remote,:pull_changes,:diff,:ls_r]
      AdminMethods = [:list_repos,:repo_url,:repo_server_dns,:footprint,:repo_name,:set_user_rights_in_repos,:remove_user_rights_in_repos,:add_user,:delete_user]

      def method_missing(name,*args,&block)
        if RepoMethods.include?(name)
          context = args.pop
          return get_repo(context).send(name,*args,&block)
        end
        if klass = class_if_admin_method?(name) 
          return klass.send(name,*args,&block)
        end
        super
      end
      def respond_to?(name)
        !!(defined_method?(name) || super)
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
          get_repo(context).delete_branch()
        end
      end
    end


    ### for dealing with actual repos
    def self.synchronize_with_remote_repo(repo_name,remote_name,remote_url)
      context = {:implementation => {:repo => repo_name, :branch => "master"}}
      repo = get_repo(context)      
      repo.add_remote(remote_name,remote_url)
      repo.pull_changes(remote_name)
      repo.push_changes()
      repo_name
    end

    def self.push_to_remote_repo(repo_name,remote_name)
      context = {:implementation => {:repo => repo_name, :branch => "master"}}
      repo = get_repo(context)      
      repo.push_changes(remote_name)
      repo_name
    end

    def self.link_to_remote_repo(repo_name,remote_name,remote_url)
      context = {:implementation => {:repo => repo_name, :branch => "master"}}
      repo = get_repo(context)      
      repo.add_remote(remote_name,remote_url)
      repo_name
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
    def self.get_repo(context)
      repo,branch = ret_repo_and_branch(context)
      raise Error.new("cannot find branch in context") unless branch
      CachedRepoObjects[repo] ||= Hash.new
      CachedRepoObjects[repo][branch] ||= load_and_create(repo,branch)
    end

   private
    CachedRepoObjects = Hash.new
    def self.ret_repo_and_branch(context)
      repo = branch = nil
      if context.kind_of?(ModuleBranch)
        repo,branch = context.repo_and_branch()
      elsif context.kind_of?(Repo)
        context.update_object!(:repo_name)
        repo = context[:repo_name]
        branch = "master"
      else
        #assume that it has hash with :implementation key
        #TODO: do we still need __top
        repo = (context[:implementation]||{})[:repo]||"__top"
        branch = (context[:implementation]||{})[:branch]
      end
      [repo,branch]
    end

    def self.load_and_return_adapter_class()
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = (R8::Config[:repo]||{})[:type]
      raise Error.new("No repo adapter specified") unless adapter_name
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class("repo_manager",adapter_name)
    end

    def self.load_and_create(repo,branch)
      klass = load_and_return_adapter_class() 
      klass.create(repo,branch)
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
