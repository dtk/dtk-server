module DTK
  module DSLParsingAux
    class LegalValues < Array
      def self.reify(input_form=nil,&legal_values_block)
        input_form.kind_of?(LegalValues) ? input_form : new(input_form,&legal_values_block) 
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

    class LegalValue
      #either input_form or legal_values_block will be nil
      def self.reify(input_form,&legal_values_block)
        if legal_values_block
          class_eval(&legal_values_block)
        elsif input_form.kind_of?(LegalValue)
          input_form
        elsif input_form.kind_of?(Class)
          Klass.new(input_form)
        else
          raise Error.new("Legal value type's class (#{input_form.class}) is not supported")
        end
      end

      #methods that can be evalued in legal_values_block
      def self.HashWithKey(keys)
        HashWithKey.new(keys)
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
