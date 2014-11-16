module DTK; class AttributeLink
  class Function
    class HashFunction < self
      def function_hash()
        @function_hash ||= self.class.function_hash?(@function_def)||{}
      end

      def self.function_hash?(function_def)
        if function_def.kind_of?(Hash) and function_def.has_key?(:function)
          function_hash = function_def[:function]
          unless function_hash and function_hash.has_key?(:name)
            raise(Error.new("Function def has illegal form: #{function_def.inspect}"))
          end
          function_hash
        end
      end
      
      def self.hash_function_name?(function_def)
        if function_hash = function_hash?(function_def)
          function_hash[:name].to_sym
        end
      end
    end
  end
end; end

