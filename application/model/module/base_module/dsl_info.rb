module DTK; class BaseModule
  class DSLInfo < Hash
    def initialize(hash={})
      super()
      replace(hash)
    end
    def dsl_parsed_info=(dsl_parsed_info)
      merge!(:dsl_parsed_info => dsl_parsed_info)
      dsl_parsed_info
    end
    def dsl_created_info=(dsl_created_info)
      merge!(:dsl_created_info => dsl_created_info)
      dsl_created_info
    end
    def dsl_updated_info=(dsl_updated_info)
      merge!(:dsl_updated_info => dsl_updated_info)
      dsl_updated_info
    end

    # has info if DSL file is created and being passed to
    class CreatedInfo < Hash
      def self.create_empty()
        new()
      end
      def self.create_with_path_and_content(path,content)
        new(:path => path, :content => content)
      end
      private
      def initialize(hash={})
        super()
        replace(hash)
      end
    end

    class UpdatedInfo < Hash
      def initialize(msg,commit_sha)
        super()
        replace(:msg => msg, :commit_sha => commit_sha)
      end
    end
  end
end; end
