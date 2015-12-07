module DTK; class ModuleBranch
  class Location
    # keys: :module_type,:component_type?,:module_name,:version?,:namespace?
    class LocalParams < Params
      def component_type
        self[:component_type]
      end

      def initialize(local_params)
        super
        @component_type = local_params[:component_type] || ret_component_type(local_params[:module_type])
      end

      class Server < self
        def create_local(project, opts = {})
          Location::Server::Local.new(project, self, opts[:new_branch_name])
        end
      end

      private

      def legal_keys
        [:module_type, :component_type?, :module_name, :version?, :namespace?, :source_name?, :branch_name?]
      end

      def ret_component_type(_module_type)
        case module_type()
         when :service_module
          :service_module
         when :component_module
          :puppet #TODO: hard wired
         when :test_module
          :test #TODO: hard wired
         when :node_module
          :node_module #TODO: hard wired
        end
      end
    end

    class Local < LocalParams
      attr_reader :project
      def initialize(project, local_params, branch_name = nil)
        super(local_params)
        @project = project
        @branch_name = branch_name if branch_name
      end

      def branch_name
        @branch_name ||= ret_branch_name()
      end

      def private_user_repo_name
        @private_user_repo_name ||= ret_private_user_repo_name()
      end
    end
  end
end; end
