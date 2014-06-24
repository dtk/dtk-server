module DTK
  class Assembly::Instance
    module ServiceLinkMixin
      def add_service_link?(input_cmp_idh,output_cmp_idh,opts={})
        raise_error_if_link_from_component_title(output_cmp_idh.create_object())
        dependency_name = find_dep_name_raise_error_if_ambiguous(input_cmp_idh,output_cmp_idh,opts)
        ServiceLink::Factory.new(self,input_cmp_idh,output_cmp_idh,dependency_name).add?()
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

     private
      def raise_error_if_link_from_component_title(cmp)
        only_one_per_node = cmp.get_field?(:only_one_per_node)
        if (!only_one_per_node.nil?) and not only_one_per_node
          raise DSLNotSupported::LinkFromComponentWithTitle.create_from_component(cmp)
        end
      end

      def find_dep_name_raise_error_if_ambiguous(input_cmp_idh,output_cmp_idh,opts={})
        input_cmp = input_cmp_idh.create_object()
        output_cmp = output_cmp_idh.create_object()
        matching_link_defs = LinkDef.get_link_defs_matching_antecendent(input_cmp,output_cmp)
        matching_link_types = matching_link_defs.map{|ld|ld.get_field?(:link_type)}.uniq

        input_cmp_name = input_cmp.component_type_print_form()
        output_cmp_name = output_cmp.component_type_print_form()

        if dep_name = opts[:dependency_name]
          if matching_link_types.include?(dep_name)
            dep_name
          else
            raise ErrorUsage.new("Specified dependency name (#{dep_name}) does not match any of the dependencies defined between component type (#{input_cmp_name}) and component type (#{output_cmp_name}): #{matching_link_types.join(',')}")
          end
        elsif matching_link_types.size == 1
          matching_link_types.first
        elsif matching_link_types.empty?
          raise ErrorUsage.new("There are no dependencies defined between component type (#{input_cmp_name}) and component type (#{output_cmp_name})")
        else #matching_link_types.size > 1
          raise ErrorUsage.new("Ambiguous which dependency between component type (#{input_cmp_name}) and component type (#{output_cmp_name}) selected; select one of #{matching_link_types.join(',')})")
        end
      end
    end
    
    class ServiceLink
      r8_nested_require('service_link','factory')    

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end

      def self.print_form_hash(object,opts={})
        # set the following (some can have nil as legal value)
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
          # TODO: confusing that input/output on port link does not reflect what is logical input/output
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
