module DTK
  class ModuleLocation
    class Local < self
      attr_reader :lcoal_branch,:repo_directory
      #  local_params = {
      #    :module_name
      #    :version (optional)
      #    :namespace (optional)
      #  }
      def initialize(local_params)
        klass = self.class
        @local_branch = klass.ret_local_branch(local_params)
        @repo_directory = klass.ret_repo_directory(local_params)
      end
    end
  end
end
