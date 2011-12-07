#TODO: incomplete; when refactored to use adapter structure; structure looked like mock used all same as grit except for clone branch
module XYZ
  class RepoManagerMock < RepoManager
    def self.create(path,branch,opts={})
      new(path,branch,opts)
    end
    def initialize(path,branch,opts={})
      raise Error.new("mock mode only supported when branch=='master'") unless  branch=="master"
      root = R8::Config[:repo][:base_directory]
      @path = "#{root}/#{path}"
    end

    def add_all_files()
    end
    def push_implementation()
    end

    def get_file_content(file_asset)
      Dir.chdir(@path){File.open(file_asset[:path]){|f|f.read}}
    end

    def self.delete_all_server_repos()
    end

    def self.repo_name(username,config_agent_type,module_name)
      "#{username}-#{config_agent_type}-#{module_name}"
    end

    def self.create_server_repo(repo_obj,repo_user_acls,opts={})
    end
    def self.create_local_repo(repo_obj,opts)
      local_repo_dir = repo_obj[:local_dir]
      repo_name = repo_obj[:repo_name]
      if File.exists?(local_repo_dir)
        if opts[:delete_if_exists]
          FileUtils.rm_rf local_repo_dir
        else
          raise Error.new("trying to create a repo (#{repo_name}) that exists already on r8 server")
        end
      end
    end
  end
end
