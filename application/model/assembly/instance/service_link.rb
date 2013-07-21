module DTK
  class Assembly::Instance
    module ServiceLinkMixin
      def add_service_link?(service_type,input_cmp_idh,output_cmp_idh)
        ServiceLink::Factory.new(self,service_type,input_cmp_idh,output_cmp_idh).add?()
      end

      def add_ad_hoc_attribute_mapping(port_link,attribute_mapping)
        ServiceLink::AttributeMapping.add(self,port_link,attribute_mapping)
      end

      def list_service_links(opts={})
        get_opts = Aux.hash_subset(opts,[:filter])
        pp_opts = Aux.hash_subset(opts,[:context])
        get_augmented_port_links(get_opts).map{|r|ServiceLink.print_form_hash(r,pp_opts)} +
          get_augmented_ports(:mark_unconnected=>true).select{|r|r[:unconnected]}.map{|r|ServiceLink.print_form_hash(r,pp_opts)}
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
          poss_conn = "#{r[:output_port][:id].to_s}:#{r[:output_port].display_name_print_form()}"
          ServiceLink.print_form_hash(r[:input_port]).merge(:possible_connection => poss_conn)
        end.sort{|a,b|a[:service_ref] <=> b[:service_ref]}
      end

    end
    
    class ServiceLink
      r8_nested_require('service_link','factory')    
      r8_nested_require('service_link','attribute_mapping')

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end

      def self.print_form_hash(object,opts={})
        #set the following (some can have nil as legal value)
        service_type = base_ref = required = description = nil
        id = object[:id]
        if object.kind_of?(PortLink)
          port_link = object
          input_port = print_form_hash__port(port_link[:input_port],port_link[:input_node])
          output_port = print_form_hash__port(port_link[:output_port],port_link[:output_node])
          service_type = port_link[:input_port].link_def_name()
          if service_type != port_link[:output_port].link_def_name()
            Log.error("input and output link defs are not equal")
          end
          #TODO: confusing that input/output on port link does not reflect what is logical input/output
          if port_link[:input_port][:direction] == "input"
            base_ref = input_port
            dep_ref = output_port
          else
            base_ref = output_port
            dep_ref = input_port
          end
        elsif object.kind_of?(Port)
          port = object
          base_ref = port.display_name_print_form()
          service_type = port.link_def_name()
          if link_def = port[:link_def] 
            required = port[:required]
            description = port[:description]
          end
        else
          raise Error.new("Unexpected object type (#{object.class.to_s})")
        end
        
        ret = {
          :id => id,
          :type => service_type,
          :base_component => base_ref
        }
        ret.merge!(:dependent_component => dep_ref) if dep_ref
        ret.merge!(:required => required) if required
        ret.merge!(:description => description) if description
        ret
      end

     private
      def self.print_form_hash__port(port,node)
        port.merge(:node=>node).display_name_print_form()
      end

    end
  end
end
