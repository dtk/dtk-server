module DTK; class ModuleBranch
  class Location
    class Local 
      attr_reader :branch_name,:repo_directory
      def initialize(project,local_params_x)
        klass = self.class
        local_params = Params.reify(local_params)
        @branch_name = klass.ret_branch_name(project,local_params)
        @repo_directory = klass.ret_repo_directory(project,local_params)
      end
      #  local_params = {
      #    :module_name
      #    :version (optional)
      #    :namespace (optional)
      #  }
      class Params
        attr_reader :module_name,:version,:namespace
        def self.reify(local_params)
          local_params.kind_of?(Params) ?  local_params : new(local_params)
        end
        def insitialize(local_params)
          @module_name = local_params[:moduele_name]
          @version = local_params[:version]
          @namespace = local_params[:namespace]
        end
      end
    end
  end
end; end
