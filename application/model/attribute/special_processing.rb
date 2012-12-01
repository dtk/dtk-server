module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      #returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr_mh,av_pair)
        #TODO: stub
        [nil,nil]
      end
    end
    class Update < self
      def self.handle_special_processing_attributes!(attr_mh,attribute_rows)
        #TODO: stub
      end
    end
  end
end; end
