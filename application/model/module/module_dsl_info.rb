module DTK
  class ModuleDSLInfo < Hash
    def initialize(hash = {})
      super()
      replace(hash)
    end

    def dsl_parse_error=(dsl_parse_error)
      merge!(dsl_parse_error: dsl_parse_error)
      dsl_parse_error
    end

    def dsl_created_info=(dsl_created_info)
      merge!(dsl_created_info: dsl_created_info)
      dsl_created_info
    end

    def dsl_updated_info=(dsl_updated_info)
      merge!(dsl_updated_info: dsl_updated_info)
      dsl_updated_info
    end

    def set_external_dependencies?(ext_deps)
      if ext_deps
        self[:external_dependencies] ||= ext_deps
      end
    end

    class Info < Hash
      def initialize(hash = {})
        raise_error_if_illegal_keys(hash.keys)
        super()
        replace(hash)
      end

      def merge(hash)
        raise_error_if_illegal_keys(hash.keys)
        super(hash)
      end

      def merge!(hash)
        raise_error_if_illegal_keys(hash.keys)
        super(hash)
      end

      private

      def raise_error_if_illegal_keys(keys)
        illegal_keys = keys - legal_keys
        unless illegal_keys.empty?
          raise Error.new("Illegal keys (#{illegal_keys.join(',')})")
        end
      end
    end

    # has info about a DSL file that is being generated
    class CreatedInfo < Info
      private

      def legal_keys
        [:path, :content, :hash_content]
      end
    end
    # has info about a DSL file that is being updated
    class UpdatedInfo < Info
      private

      def legal_keys
        [:msg, :commit_sha]
      end
    end
  end
end
