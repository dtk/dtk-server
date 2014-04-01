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
      attr_reader :remote_branch,:remote_ref,:remote_url
      def initialize(project,remote_params)
        super(remote_params)
      end
    end
  end
end; end

