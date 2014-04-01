module DTK; class ModuleBranch
  class Location
    #  local_params = {
    #    :module_name
    #    :version (optional)
    #    :namespace (optional)
    #  }
    class LocalParams < Params
     private
      def legal_keys()
        [:module_name,:version?,:namespace?]
      end
    end    

    class Local < LocalParams
      attr_reader :branch_name,:repo_directory
      def initialize(project,local_params)
        super(local_params)
        klass = self.class
        @branch_name = klass.ret_branch_name(project,self)
        @repo_directory = klass.ret_repo_directory(project,self)
      end

    end
  end
end; end
