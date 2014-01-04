module DTK
  class ErrorUsage
    class DSLParsing < self #comes from dtk-commin/lib/dsl/file_parser
      class YAMLParsing < self
      end

      def self.raise_error_unless(object,legal_values_input_form=[],&legal_values_block)
        legal_values = LegalValues.reify(legal_values_input_form,&legal_values_block)
        unless legal_values.match?(object)
          raise WrongType.new(object,legal_values,&legal_values_block)
        end
      end

      class WrongType < self
        def initialize(object,legal_values=[],&legal_values_block)
          super(LegalValues.reify(legal_values,&legal_values_block).error_message(object))
        end
      end

      class LegalValues < Array
        def self.reify(object=nil,&legal_values_block)
          object.kind_of?(LegalValues) ? object : new(object,&legal_values_block) 
        end
        def match?(object)
          !!find{|el|el.matches?(object)}
        end
        def error_message(object)
          msg = "Parsing Error: Object (#{object_print_form(object)}) should have "
          if size == 1
            msg << "type (#{first.print_form()})"
          else
            msg << "a type from (#{map{|el|el.print_form()}.join(',')})"
          end
          msg
        end

       private
        def initialize(input_form=nil,&legal_values_block)
          array = Array(input_form).map{|el|LegalValue.reify(el)}
          if legal_values_block
            array += Array(instance_eval(&legal_values_block))
          end
          super(array)
        end
        def object_print_form(object)
          object.inspect()
        end

        #methods that can be evalued in legal_values_block
        def HashWithKey(keys)
          LegalValue::HashWithKey.new(keys)
        end
      end

      #TODO: stub that only has element which is class, tehn support form where hash first element class second is contraint
      class LegalValue
        def self.reify(input_form)
          if input_form.kind_of?(LegalValue)
            input_form
          else
            Klass.new(input_form)
          end
        end

        class Klass < self
          def initialize(klass)
            @klass = klass
          end
          def matches?(object)
            object.kind_of?(@klass)
          end
          def print_form()
            @klass.to_s
          end
        end

        class HashWithKey
          def initialize(keys)
            @keys = Array(keys).map{|k|k.to_s}
          end
          def matches?(object)
            object.kind_of?(Hash) and object.size == 1 and @keys.include?(object.keys.first.to_s)
          end
           def print_form()
             "HashWithKey(#{@keys.join(',')})"
           end
        end
      end
    end
  end
end

