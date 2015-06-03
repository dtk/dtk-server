module DTK; class ActionDef; class Content
  class Command
    class RubyFunction < self
      attr_reader :ruby_function

      def needs_template_substitution?()
        @needs_template_substitution
      end

      def initialize(ruby_function)
        @ruby_function = ruby_function
      end

      def process_function_assign_attrs(attrs, dyn_attrs)
        @ruby_function.each_pair do |d_attr, fn|
          begin
            evaluated_fn = proc {
              $SAFE = 4
              eval(fn)
            }.call

            attr_id  = (attrs.find{|a| a[:display_name].eql?(d_attr.to_s)}||{})[:id]
            attr_val = calculate_dyn_attr_value(evaluated_fn, attrs)
            dyn_attrs << {:attribute_id => attr_id, :attribute_val => attr_val}
          rescue SecurityError => e
            pp [e,e.backtrace[0..5]]
            return {:error => e}
          end
        end
      end

      def self.parse?(serialized_command)
        if serialized_command.kind_of?(Hash) && serialized_command.has_key?(:outputs)
          ruby_function = serialized_command[:outputs]
          new(ruby_function)
        end
      end

      def calculate_dyn_attr_value(evaluated_fn, attrs)
        value = nil
        parsed_attrs = parse_attributes(attrs)
        if evaluated_fn.is_a?(Proc) && evaluated_fn.lambda?
          params = process_lambda_params(evaluated_fn, parsed_attrs)#evaluated_fn.parameters
          value = evaluated_fn.call(*params)
        else
          raise Error.new("Currently only lambda functions are supported")
        end
        value
      end

      def process_lambda_params(lambda_fn, parsed_attrs)
        ret_params = []
        lambda_fn.parameters.each do |pm|
          ret_params << parsed_attrs[pm[1].to_s]
        end
        ret_params
      end

      def parse_attributes(attrs)
        parsed_attrs = {}
        attrs.each do |attr|
          if attr[:data_type].eql?('integer')
            parsed_attrs[attr[:display_name]] = (attr[:value_asserted]||attr[:value_derived]).to_i
          else
            parsed_attrs[attr[:display_name]] = attr[:value_asserted] || attr[:value_derived]
          end
        end
        parsed_attrs
      end

      def type()
        'ruby_function'
      end
    end
  end
end; end; end              
