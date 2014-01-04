module DTK
  class ErrorUsage
    class DSLParsing < self #comes from dtk-commin/lib/dsl/file_parser
      class YAMLParsing < self
      end

      def self.raise_error_unless(object,legal_values_input_form)
        legal_values = LegalValues.reify(legal_values_input_form)
        unless legal_values.match?(object)
          raise WrongType.new(object,legal_values)
        end
      end

      class WrongType < self
        def initialize(object,legal_values)
          super(LegalValues.reify(legal_values).error_message(object))
        end
      end

      class LegalValues < Array
        def self.reify(object)
          object.kind_of?(LegalValues) ? object : new(object) 
        end
        def match?(object)
          !!find{|el|el.matches?(object)}
        end
        def error_message(object)
          msg = "Parsing Error: Object (#{object_print_form(object)}) should have "
          if size == 1
            msg << "type (#{first.print_form()})"
          else
            msg << "types (#{map{|el|el.print_form().join(',')}})"
          end
          msg
        end

       private
        def initialize(input_form)
          super(Array(input_form).map{|el|LegalValue.reify(el)})
        end
        def object_print_form(object)
          object.inspect()
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
      end
    end
  end
end

