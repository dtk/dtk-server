#TODO: this needs cleanup
module DTK
  module WorkflowAdapter
    class AgentGritAdapter

      # Mutex is required, as this method will be invoked from concurrent subtasks, and grit is not thread safe
      @@grit_lock = Mutex.new
      
      def self.get_head_git_commit_id()          
        head_commit_id = nil
        @@grit_lock.synchronize do 
          # TODO Amar put this into configuration if needed
          agent_repo_dir = "#{R8::Config[:repo][:base_directory]}/dtk-node-agent"
          agent_repo_url = "https://github.com/rich-reactor8/dtk-node-agent.git"
          # Clone will be invoked only when DTK Server is started for the first time
          unless File.directory?("#{agent_repo_dir}")
            cmd_opts = {:raise => true, :timeout => GitOpTimeout}
            clone_args = [agent_repo_url, agent_repo_dir]
            ::Grit::Git.new("").clone(cmd_opts, *clone_args)
          end
            
          # Amar:
          # git pull(fetch/merge) will be invoked each time, 
          # but this operation is very fast (few ms of roundtrip) when no changes present 
          # To execute git pull from outside project directory, work-tree param must be set.
          # I haven't found a way through grit to set it, but to execute lowest method and make my own command
          repo = ::Grit::Repo.new("#{agent_repo_dir}")
          cmd_opts = {:timeout => GitOpTimeout}
          #TODO: change call; grit call git.run is being deprecated
          repo.git.run("", "--work-tree=#{agent_repo_dir} fetch", "", cmd_opts, {})
          repo.git.run("", "--work-tree=#{agent_repo_dir} merge 'origin/master'", "", cmd_opts, {})
          
          head_commit_id = repo.commits.first.id
        end
        head_commit_id
      end
      GitOpTimeout = 10
    end
  end
end
