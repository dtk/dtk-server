module DTK; class Attribute
  class SpecialProcessing
    r8_nested_require('special_processing','value_check')
    r8_nested_require('special_processing','update')
   private

    def self.needs_special_processing?(attr)
      if attr_info = attr_info(attr)
        attr_info[:filter].call(attr)
      end
    end

    def self.attr_info(attr)
      ret_special_processing_info()[attr[:display_name].to_sym]
    end
  end
end; end
