#TODO: when move to Rugged clean up the git refernces
module DTK
  module WorkflowAdapter
    class AgentGritAdapter
      # Mutex is required, as this method will be invoked from concurrent subtasks, and grit is not thread safe
      @@grit_lock = Mutex.new
      def self.get_head_git_commit_id()          
        head_commit_id = nil
        @@grit_lock.synchronize do 
          # TODO Amar put this into configuration if needed
          agent_repo_dir = R8::Config[:node_agent_git_clone][:local_dir]
          agent_repo_url = R8::Config[:node_agent_git_clone][:remote_url]
          agent_repo_branch = R8::Config[:node_agent_git_clone][:branch]
          repo = nil
          # Clone will be invoked only when DTK Server is started for the first time
          #or agent_repo_branch changed
          unless File.directory?(agent_repo_dir)
            cmd_opts = { :raise => true, :timeout => 10 }
            clone_args = [agent_repo_url, agent_repo_dir]
            unless agent_repo_branch == 'master'
              clone_args += ['-b',agent_repo_branch]
            end
            GitCommandHelper.clone(cmd_opts,clone_args)
          else
            #check if R8::Config[:node_agent_git_clone][:branch] changed
            git_cmd_helper = GitCommandHelper.new(agent_repo_dir)
            unless agent_repo_branch == git_cmd_helper.branch_head_name()
              git_cmd_helper.execute(:fetch)
              git_cmd_helper.execute(:checkout,agent_repo_branch)
            end
          end

          #when get heer will be on right branch
          git_cmd_helper ||= GitCommandHelper.new(agent_repo_dir)
          git_cmd_helper.execute(:pull,"origin",agent_repo_branch)
          head_commit_id = git_cmd_helper.branch_head_id()
        end
        head_commit_id
      end
     private
      class GitCommandHelper
        def initialize(agent_repo_dir)
          @repo = ::Grit::Repo.new(agent_repo_dir)
          @work_tree = agent_repo_dir
        end

        def self.clone(cmd_opts,clone_args)
           ::Grit::Git.new("").clone(cmd_opts, *clone_args)
        end

        def execute(cmd,*cmd_args)
          @repo.git.send(cmd,cmd_opts(),cmd_args)
        end
        
        def branch_head_name()
          @repo.head.name
        end
        def branch_head_id()
          @repo.commits.first.id
        end
       private
        def cmd_opts()
          {:raise => true, :timeout => 10}
        end
      end
    end
  end
end
