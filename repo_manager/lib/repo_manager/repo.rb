r8_require('grit_adapter') #TODO: since just one adapter now not dynamically loading in
module DTK::RepoManager
  class Repo 
    def adapter_class()
      GritAdapter::ObjectAccess
    end
    def initialize(repo_name,branch='master')
      #updating and querying from the bare repo   
      @repo = adapter_class.new(bare_repo_dir(repo_name),branch)
    end
    
    def add_file_and_commit(file_path,content,commit_msg=nil)
      commit_context(commit_msg||"adding file #{file_path}") do
        @repo.add_or_replace_file(file_path,content)
      end
    end
    def update_file_and_commit(file_path,content,commit_msg=nil)
      commit_context(commit_msg||"updating file #{file_path}") do
        @repo.add_or_replace_file(file_path,content)
      end
    end

    def delete_file_and_commit(file_path,commit_msg=nil)
      commit_msg = "updating file #{file_path}"
      commit_context(commit_msg||"deleting file #{file_path}") do
        @repo.delete_file(content)
      end
    end

    #TODO: put /^r8meta\.puppet/, "component_module_puppet", etc in lib common 
    def self.get_type(repo_name)
      level = 1
      first_level_files = new(repo_name).ls_r(level) 
      if first_level_files.find{|p|p =~ /^r8meta\.puppet/}
        "component_module_puppet"
      elsif first_level_files.find{|p|p =~ /^r8meta\.puppet/}
        "component_module_chef"
      else
        "service_module"
      end
    end

    #'pass' all these methods to @repo
    RepoMethods = [:add_or_replace_file,:branches,:create_branch,:file_content,:ls_r,:commit_context]
    def method_missing(name,*args,&block)
      if RepoMethods.include?(name)
        @repo.send(name,*args,&block)
      else
        super
      end
    end
    def respond_to?(name)
      !!(RepoMethods.include?(name) || super)
    end
   private
    def bare_repo_dir(repo_name)
      ::DTK::RepoManager::bare_repo_dir(repo_name)
    end
  end
end
