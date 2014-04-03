module DTK; class ModuleBranch
  class Location
    #  remote_params = {
    #    :remote_repo_base
    #    :namespace
    #    :module_name
    #    :version 
    #  }
    class RemoteParams < Params
      def remote_repo_base()
        self[:remote_repo_base]
      end
     private
      def legal_keys()
        [:module_type,:module_name,:remote_repo_base,:version?,:namespace?]
      end
    end
    class Remote < RemoteParams 
      def initialize(project,remote_params)
        super(remote_params)
        @project = project
      end
      def branch_name()
        @branch_name ||= ret_branch_name()
      end
      def remote_ref()
        @remote_ref ||= ret_remote_ref()
      end
     private
      def ret_remote_ref()
        "#{remote_repo_base}--#{namespace}"
      end
      def ret_branch_name()
        if version.nil? or version == HeadBranchName
          HeadBranchName
        else
          "v#{version}"
        end
      end
      HeadBranchName = "master"
    end
  end
end; end

