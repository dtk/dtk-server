require 'grit'

# GRIT DEBUG HERE
# 
# Grit.debug = true
#
#
module DTK::RepoManager
  class GritAdapter
  end
end
r8_nested_require('grit_adapter','file_access')
r8_nested_require('grit_adapter','object_access')
module DTK::RepoManager
  class GritAdapter 
    def initialize(repo_dir,branch='master')
      @repo_dir = repo_dir
      @branch = branch
      @grit_repo = nil
      begin
        @grit_repo = ::Grit::Repo.new(repo_dir)
       rescue ::Grit::NoSuchPathError
        repo_name = repo_dir.split("/").last.gsub("\.git","")
        #TODO: change to usage error
        raise Error.new("repo (#{repo_name}) does not exist")
       rescue => e
        raise e
      end
    end

    def branches()
      @grit_repo.branches.map{|h|h.name}
    end

    def ls_r(depth=nil,opts={})
      tree_contents = tree.contents
      ls_r_aux(depth,tree_contents,opts)
    end

    def path_exists?(path)
      not (tree/path).nil?
    end

    def file_content(path)
      tree_or_blob = tree/path
      tree_or_blob && tree_or_blob.kind_of?(::Grit::Blob) && tree_or_blob.data
    end

    def push()
      Git_command__push_mutex.synchronize do 
        git_command(:push,"origin", "#{@branch}:refs/heads/#{@branch}")
      end
    end
    def push_to_mirror_repo(mirror_repo)
      git_command(:push,"--mirror",mirror_repo)
    end
    Git_command__push_mutex = Mutex.new

    def pull()
      git_command(:pull,"origin",@branch)
    end

   private
    def tree()
      @grit_repo.tree(@branch)
    end

    def ls_r_aux(depth,tree_contents,opts={})
      ret = Array.new
      return ret if tree_contents.empty?
      if depth == 1
        ret = tree_contents.map do |tc|
          if opts[:file_only]
            tc.kind_of?(::Grit::Blob) && tc.name 
          elsif opts[:directory_only]
            tc.kind_of?(::Grit::Tree) && tc.name
          else
            tc.name
          end
        end.compact
        return ret
      end

      tree_contents.each do |tc|
        if tc.kind_of?(::Grit::Blob)
          unless opts[:directory_only]
            ret << tc.name
          end
        else
          dir_name = tc.name
          ret += ls_r_aux(depth && depth-1,tc.contents).map{|r|"#{dir_name}/#{r}"}
        end
      end
      ret
    end

    def git_command(cmd,*args)
      @grit_repo.git.send(cmd, cmd_opts(),*args)
    end
    def cmd_opts()
      {:raise => true, :timeout => 60}
    end

  end
end
