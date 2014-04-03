module DTK
  class Repo
    class WithBranch < self
      def self.create_empty_workspace_repo(project_idh,local,repo_user_acls,opts={})
        repo_mh = project_idh.createMH(:repo)
        ret = create_obj?(repo_mh,local)
        repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
        RepoUserAcl.modify_model(repo_idh,repo_user_acls)
        RepoManager.create_empty_workspace_repo(ret,repo_user_acls,opts) 
        ret
      end
      
     private
      def self.create_obj?(model_handle,local)
        repo_name = local.repo_name
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
        repo_obj.merge(:branch_name => branch_name)
      end
      
      def self.get_objs(model_handle,sp_hash,opts={})
        super(model_handle,sp_hash,{:subclass_model_name => :repo_with_branch}.merge(opts))
      end
    end
  end
end
