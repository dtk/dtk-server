module DTK; class AttributeLink
  class Function::WithArgs
    class FunctionInfo
      attr_reader :name,:constants
      def initialize(name,constants_hash)
        @name = name.to_sym
        @constants = Constants.new(constants_hash)
      end

      def self.create(function_def)
        unless ret = create?(function_def)
          raise Error.new("Error creating (#{function_def.inspect})")
        end
        ret
      end
      def self.create?(function_def)
        if function_def.is_a?(Hash) && function_def.key?(:function)
          fn_info_hash = function_def[:function]
          unless fn_info_hash && fn_info_hash.key?(:name)
            raise(Error.new("Function def has illegal form: #{function_def.inspect}"))
          end
          new(fn_info_hash[:name],fn_info_hash[:constants]||{})
        end
      end

      class Constants < Hash
        def initialize(hash)
          super()
          replace(hash)
        end

        def [](k)
          unless key?(k)
            raise Error.new("New constant (#{k}) found")
          end
          super
        end
      end
    end
  end
end; end
