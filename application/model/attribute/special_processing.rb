module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      #returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr,new_val)
        pp [attr,new_val]
        #TODO: stub
        [nil,nil]
      end
    end
    class Update < self
      def self.handle_special_processing_attributes(existing_attrs,ndx_new_vals)
        #TODO: stub
      end
    end
  end
end; end
