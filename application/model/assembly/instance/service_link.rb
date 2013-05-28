module DTK
  class Assembly::Instance
    module ServiceLinkMixin
      def add_ad_hoc_service_link?(service_type,input_cmp_idh,output_cmp_idh)
        ServiceLink::AdHocLink.new(self,service_type,input_cmp_idh,output_cmp_idh).add?()
      end

      def add_ad_hoc_attribute_mapping(port_link,attribute_mapping)
        ServiceLink::AttributeMapping.add(self,port_link,attribute_mapping)
      end

      def delete_service_link(filter)
        port_link = get_matching_port_link(filter)
        Model.delete_instance(port_link.id_handle())
      end

      def list_connections(opts={})
        get_augmented_port_links(opts).map{|r|r.print_form_hash()}
      end
      
      def list_connections__missing()
        get_augmented_ports(:mark_unconnected=>true).select{|r|r[:unconnected]}.map{|r|r.print_form_hash()}
      end

      def list_connections__possible()
        ret = Array.new
        output_ports = Array.new
        unc_ports = Array.new
        get_augmented_ports(:mark_unconnected=>true).each do |r|
          if r[:direction] == "output"
            output_ports << r 
          elsif r[:unconnected]
            unc_ports << r 
          end
        end
        return ret if output_ports.nil? or unc_ports.nil?
        poss_conns = LinkDef.find_possible_connections(unc_ports,output_ports)
        poss_conns.map do |r|
          poss_conn = "#{r[:output_port][:id].to_s}: #{r[:output_port].print_form_hash()[:service_ref]}"
          r[:input_port].print_form_hash().merge(:possible_connection => poss_conn)
        end.sort{|a,b|a[:service_ref] <=> b[:service_ref]}
      end

    end
    
    class ServiceLink
      r8_nested_require('service_link','ad_hoc_link')    
      r8_nested_require('service_link','attribute_mapping')

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end
    end
  end
end
