module XYZ
  class Repo 
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

    def self.delete(context)
      get_repo(context).delete()
    end

    def self.delete_all_branches()
      repos = nil
      Dir.chdir(R8::EnvironmentConfig::CoreCookbooksRoot) do
        repos = Dir["*"].reject{|item|File.file?(item)}
      end
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
          get_repo(context).delete()
        end
      end
    end
   private
    def self.get_repo(context)
      #TODO: do we still need __top
      repo = (context[:implementation]||{})[:repo]||"__top"
      branch = (context[:implementation]||{})[:branch]
      raise Error.new("cannot find branch in context") unless branch
      CachedRepoObjects[repo] ||= Hash.new
      CachedRepoObjects[repo][branch] ||= load_and_create(repo,branch)
    end

    CachedRepoObjects = Hash.new
    def self.load_and_create(path,branch)
      type = (R8::Config[:repo]||{})[:type]
      raise Error.new("No repo adapter specified") unless type
      klass = self
      begin
        Lock.synchronize{r8_nested_require("repo/adapters",type)}
        klass = XYZ.const_get "Repo#{type.to_s.capitalize}"
      rescue LoadError
        raise Error.new("cannot find repo adapter (#{type})")
      end
      klass.create(path,branch)
    end
  end
end
