module DTK; class Repo
  class Remote
    class Info < Hash
      #has keys
      #  :remote_repo_url
      #  :remote_repo 
      #  :remote_branch
      #  :module_name
      #  :version
      def initialize(parent,branch_obj,remote_params)
        super()
        remote_repo = @remote_repo||parent.default_remote_repo()
        hash = {
          :module_name => remote_params[:module_name],
          :remote_repo => remote_repo.to_s,
          :remote_repo_url => parent.repo_url_ssh_access(remote_params[:remote_repo_name]),
          :remote_branch => parent.version_to_branch_name(remote_params[:version]),
          :workspace_branch => branch_obj.get_field?(:branch)
        }
        hash.merge!(:version => remote_params[:version]) if remote_params[:version]
        replace(hash)
      end
    end
  end
end; end
