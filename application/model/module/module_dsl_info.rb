module DTK
  class ModuleDSLInfo < Hash
    def initialize(hash = {})
      super()
      replace(hash)
    end

    def dsl_parse_error=(dsl_parse_error)
      self[:dsl_parse_error] = dsl_parse_error
    end

    def dsl_created_info=(dsl_created_info)
      self[:dsl_created_info] = dsl_created_info
    end

    def dsl_updated_info=(dsl_updated_info)
      self[:dsl_updated_info] = dsl_updated_info
    end

    def parsed_dsl
      raise_error_if_unset(:parsed_dsl)
      self[:parsed_dsl]
    end
    def set_parsed_dsl?(parsed_dsl)
      self[:parsed_dsl] = parsed_dsl if parsed_dsl
    end

    def set_external_dependencies?(ext_deps)
      self[:external_dependencies] ||= ext_deps if ext_deps
    end

    def hash_subset(*keys)
      Aux.hash_subset(self, keys)
    end

    private

    def raise_error_if_unset(key)
      fail Error.new("Accessor '#{key}' should not be called when it is unset") unless has_key?(key)
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
          fail Error.new("Illegal keys (#{illegal_keys.join(',')})")
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
