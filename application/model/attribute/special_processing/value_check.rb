module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      # returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr,new_val)
        error = nil
        if attr_info = needs_special_processing?(attr)
          error = error?(attr,attr_info,new_val)
        end
        special_processing = (not attr_info.nil?)
        [special_processing,error]
      end

     private
      def self.error?(attr,attr_info,new_val)
        if legal_values = LegalValues.create?(attr,attr_info)
          unless legal_values.include?(new_val)
            LegalValue::Error.new(attr,new_val,:legal_values => legal_values.print_form)
          end
        end
      end
    end
  end
end; end
