module DTK; class ErrorUsage
  class Parsing
    class LegalValues < Array
      def self.reify(input_form=nil,&legal_values_block)
        input_form.is_a?(LegalValues) ? input_form : new(input_form,&legal_values_block)
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
      def self.match?(object,input_form=nil,&legal_values_block)
        legal_val = LegalValue.reify(input_form,&legal_values_block)
        legal_val.matches?(object)
      end
      def add_and_match?(object,input_form=nil,&legal_values_block)
        legal_val = LegalValue.reify(input_form,&legal_values_block)
        self << legal_val
        legal_val.matches?(object)
      end

      private

      def initialize(input_form=nil,&legal_values_block)
        array = Array(input_form).map{|el|LegalValue.reify(el)}
        if legal_values_block
          array += LegalValue.reify(&legal_values_block)
        end
        super(array)
      end

      def object_print_form(object)
        object.inspect()
      end
    end
  end
end; end
