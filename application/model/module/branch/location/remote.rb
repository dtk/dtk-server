module DTK; class ModuleBranch
  class Location
    class RemoteParams < Params
      #keys: :module_type,:module_name,:remote_repo_base,:namespace,:version?
      def remote_repo_base()
        self[:remote_repo_base]
      end
     private
      def legal_keys()
        [:module_type,:module_name,:remote_repo_base,:namespace,:version?]
      end
    end
    class Remote < RemoteParams 
      attr_reader :project
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
      HeadBranchName = 'master'
    end
  end
end; end

