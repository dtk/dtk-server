module DTK; class ModuleBranch
  class Location
    #  local_params = {
    #    :module_name
    #    :version (optional)
    #    :namespace (optional)
    #    :component_type (optioonally put in as input, but filled in from default if needed
    #  }
    class LocalParams < Params
      def component_type()
        self[:component_type]
      end
      def initialize(local_params)
        super
        @component_type = local_params[:component_type]||ret_component_type(local_params[:module_type])
      end
     private
      def legal_keys()
        [:module_type,:component_type?,:module_name,:version?,:namespace?]
      end
      def ret_component_type(module_type)
        case module_type()
         when :service_module 
          :service_module
         when :component_module
          :puppet #TODO: hard wired
        end
      end
    end    

    class Local < LocalParams
      def initialize(project,local_params)
        super(local_params)
        @project = project
      end
      def branch_name()
        @branch_name ||= ret_branch_name()
      end
      def repo_directory()
        @repo_directory ||= ret_repo_directory()
      end
      def private_user_repo_name()
        @private_user_repo_name ||= ret_private_user_repo_name()
      end
    end
  end
end; end
