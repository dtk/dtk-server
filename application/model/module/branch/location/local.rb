module DTK; class ModuleBranch
  class Location
    #  local_params = {
    #    :module_name
    #    :version (optional)
    #    :namespace (optional)
    #  }
    class LocalParams < Hash
      def module_name()
        self[:module_name]
      end
      def version()
        self[:version]
      end
      def namespace()
        self[:namespace]
      end
      def initialize(local_params)
        unless local_params.kind_of?(LocalParams)
          validate(local_params)
        end
        replace(local_params)
      end
     private
      def validate(local_params)
        unless (bad_keys = local_params.keys - Keys).empty?
          raise Error.new("Illegal key(s) (#{bad_keys.join(',')})")
        end
        if local_params[:module_name].nil?
          raise Error.new("Required key: module_name")
        end
      end
      Keys = [:module_name,:version,:namespace]
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
