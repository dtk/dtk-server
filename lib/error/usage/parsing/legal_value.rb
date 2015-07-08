module DTK; class ErrorUsage
  class Parsing
    class LegalValue
      # either input_form or legal_values_block will be nil
      def self.reify(input_form,&legal_values_block)
        if legal_values_block
          class_eval(&legal_values_block)
        elsif input_form.is_a?(LegalValue)
          input_form
        elsif input_form.is_a?(Class)
          Klass.new(input_form)
        else
          raise Error.new("Legal value type's class (#{input_form.class}) is not supported")
        end
      end

      # methods that can be evalued in legal_values_block
      def self.HashWithKey(*keys)
        HashWithKey.new(keys)
      end
      def self.HashWithSingleKey(*keys)
        HashWithSingleKey.new(keys)
      end

      class Klass < self
        def initialize(klass)
          @klass = klass
        end

        def matches?(object)
          object.is_a?(@klass)
        end

        def print_form
          @klass.to_s
        end
      end
      class HashWithKey
        def initialize(keys)
          @keys = Array(keys).map(&:to_s)
        end

        def matches?(object)
          object.is_a?(Hash) && !!object.keys.find{|k|@keys.include?(k.to_s)}
        end

        def print_form
          "HashWithKey(#{@keys.join(',')})"
        end
      end
      class HashWithSingleKey
        def initialize(keys)
          @keys = Array(keys).map(&:to_s)
        end

        def matches?(object)
          object.is_a?(Hash) && object.size == 1 && @keys.include?(object.keys.first.to_s)
        end

        def print_form
          "HashWithSingleKey(#{@keys.join(',')})"
        end
      end
    end
  end
end; end
