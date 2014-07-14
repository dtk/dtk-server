module DTK; class ModuleBranch
  class Location
    # keys: :module_type,:component_type?,:module_name,:version?,:namespace?
    class LocalParams < Params
      def component_type()
        self[:component_type]
      end
      def initialize(local_params)
        super
        @component_type = local_params[:component_type]||ret_component_type(local_params[:module_type])
      end

      class Server < self
        def create_local(project)
          Location::Server::Local.new(project,self)
        end
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
         when :test_module
          :test #TODO: hard wired
        end
      end
    end

    class Local < LocalParams
      attr_reader :project
      def initialize(project,local_params)
        super(local_params)
        @project = project
      end
      def branch_name()
        @branch_name ||= ret_branch_name()
      end
      def private_user_repo_name()
        @private_user_repo_name ||= ret_private_user_repo_name()
      end
    end
  end
end; end
