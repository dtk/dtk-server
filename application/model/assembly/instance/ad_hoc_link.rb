module DTK
  class Assembly::Instance
    module AdHocLinkMixin
      def add_ad_hoc_service_link?(service_type,input_cmp_idh,output_cmp_idh)
        AdHocLink::ServiceLink.new(self,service_type,input_cmp_idh,output_cmp_idh).add?()
      end

      def add_ad_hoc_attribute_mapping(port_link_idh,attribute_mapping)
        AdHocLink::AttributeMapping.add(self,port_link_idh,attribute_mapping)
      end
    end
    
    class AdHocLink
      r8_nested_require('ad_hoc_link','service_link')    
      r8_nested_require('ad_hoc_link','attribute_mapping')

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end
    end
  end
end
