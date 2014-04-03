module DTK
  class Repo
    class WithBranch < self
      def self.create_empty_workspace_repo(project_idh,local,repo_user_acls,opts={})
        repo_mh = project_idh.createMH(:repo)
        ret = create_obj?(repo_mh,local)
        repo_idh = repo_mh.createIDH(:id => ret.id)
        RepoUserAcl.modify_model(repo_idh,repo_user_acls)
        RepoManager.create_empty_workspace_repo(ret,repo_user_acls,opts) 
        ret
      end

      def initial_sync_with_remote(remote,remote_repo_info)
        unless R8::Config[:repo][:workspace][:use_local_clones]
          raise Error.new("Not implemented yet: initial_sync_with_remote_repo w/o local clones")
        end
        
        remote_url = RepoManagerClient.repo_url_ssh_access(remote_repo_info[:git_repo_name])
        remote_ref = remote.remote_ref()
        remote_branch =  remote.branch_name()

        if remote_branches = remote_repo_info[:branches]
          unless remote_branches.include?(remote_branch)
            raise ErrorUsage.new("Cannot find selected version on remote repo #{remote_repo_info[:full_name]||''}")
          end
        end
        commit_sha = RepoManager.initial_sync_with_remote_repo(branch_name(),get_field?(:repo_name),remote_ref,remote_url,remote_branch)
        commit_sha
      end
      
     private
      def self.create_obj?(model_handle,local)
        repo_name = repo_name(local)
        branch_name = local.branch_name
        sp_hash = {
          :cols => common_columns(),
          :filter => [:eq,:repo_name,repo_name]
        }
        unless repo_obj = get_obj(model_handle,sp_hash)
          repo_hash = {
            :ref => repo_name,
            :display_name => repo_name,
            :repo_name => repo_name,
            :local_dir =>  "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
          }
          repo_idh = create_from_row(model_handle,repo_hash)
          repo_obj = repo_idh.create_object(:model_name => :repo_with_branch).merge(repo_hash)
        end
        set_branch_name!(repo_obj,branch_name)
      end

      def self.set_branch_name!(repo_obj,branch_name)
        repo_obj.merge!(:branch_name => branch_name)
      end
      def branch_name()
        unless ret = self[:branch_name]
          raise Error.new("Unexpected that self[:branch_name] is null for: #{inspect()}")
        end
        ret
      end

      def self.repo_name(local)
        local.private_user_repo_name()
      end
      
      def self.get_objs(mh,sp_hash,opts={})
        model_handle = (mh[:model_name] == :repo_with_branch ? mh.createMH(:repo) : mh)
        super(model_handle,sp_hash,{:subclass_model_name => :repo_with_branch}.merge(opts))
      end
    end
  end
end
