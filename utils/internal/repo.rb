module XYZ
  class Repo 
    #### for interacting with existing repos"
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

    def self.delete_all_branches()
      repos = load_and_return_adapter_class().get_all_repos()
      delete_branches(*repos)
    end
    def self.delete_branches(*repos)
      repos.each do |repo|
        get_branches(repo).each do |branch|
          next if branch == "master"
          pp "deleting branch (#{branch}) in repo (#{repo})"
          context = {
            :implementation => {
            :repo => repo,
            :branch => branch
            }
          }
          get_repo(context).delete_branch()
        end
      end
    end

    ###### for creating and deleting repositories
    def self.create_repo?(model_handle,repo,create_context)
      klass = load_and_return_adapter_class()
      return if RepoMeta.get_all_repo_names().include?(repo) 
      create_repo(model_handle,repo,create_context,klass)
    end
    def self.create_repo(model_handle,repo,create_context,klass=nil)
      klass ||= load_and_return_adapter_class()
      new_repo = klass.create_repo(repo,create_context)
      RepoMeta.add_new_repo(model_handle,new_repo,create_context)
    end

    def self.get_repo(context)
      #TODO: do we still need __top
      repo = (context[:implementation]||{})[:repo]||"__top"
      branch = (context[:implementation]||{})[:branch]
      raise Error.new("cannot find branch in context") unless branch
      CachedRepoObjects[repo] ||= Hash.new
      CachedRepoObjects[repo][branch] ||= load_and_create(repo,branch)
    end
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
  end
end
