module DTK
  class ServiceModule; class AssemblyExport
    class V2 < self
     private
      def serialize()
        assembly_hash = assembly_output_hash()
        node_bindings_hash = node_bindings_output_hash()
        SimpleOrderedHash.new(
         [
          {:name => assembly_hash()[:display_name]},
          {:node_bindings => node_bindings_hash}, 
          {:assembly => assembly_hash}
         ])
      end

      def assembly_output_hash()
        ret = SimpleOrderedHash.new()
        #add assembly level attributes
        #TODO: stub
      
        #TODO: need to add in component overide values
        #add nodes and components
        node_ref_to_name = Hash.new
        ret[:nodes] = self[:node].inject(SimpleOrderedHash.new()) do |h,(node_ref,node_hash)|
          node_name = node_hash[:display_name]
          node_ref_to_name[node_ref] = node_name
          cmp_info = node_hash[:component_ref].values.map{|cmp|component_output_form(cmp)}
          h.merge(node_name => {:components => cmp_info})
        end

        #add in port links
        self[:port_link].values.each do |pl|
          in_parsed_port = parse_port_ref(pl["*input_id"],node_ref_to_name)
          out_parsed_port  = parse_port_ref(pl["*output_id"],node_ref_to_name)
          unless matching_node = ret[:nodes][in_parsed_port[:node_name]]
            raise Error.new("Cannot find matching node for input port")
          end

          #TODO: does this need fixing up in cases whare a component can appear multiple times?
          cmps = matching_node[:components]
          i = 0; found = false
          while i < cmps.size and !found
            if match_component?(cmps[i],in_parsed_port[:component_name])
              cmps[i] = add_service_link_to_cmp(cmps[i],out_parsed_port)
              found = true
            end
            i = i+1
          end
          unless found
            raise Error.new("Cannot find matching component for input port")
          end
        end
        ret
      end

      def parse_port_ref(qualified_port_ref,node_ref_to_name)
        port_ref = qualified_port_ref.split("/").last
        p = Port.parse_external_port_display_name(port_ref)
        node_ref = (qualified_port_ref =~ Regexp.new("^/node/([^/]+)");$1)
        component_name = component_name_output_form(p[:component_type])
        {:node_name => node_ref_to_name[node_ref], :component_name => component_name, :link_def_ref => p[:link_def_ref]}
      end

      def match_component?(component_in_ret,component_name)
        match_term = 
          if component_in_ret.kind_of?(Hash)
            component_in_ret.keys.first
          else # it will be a string
            component_in_ret
          end
        match_term == component_name
      end

      def add_service_link_to_cmp(component_in_ret,out_parsed_port)
        ret = Hash.new
        if component_in_ret.kind_of?(Hash)
          ret = component_in_ret
          service_links = ret.values.first[:service_links] ||= Hash.new
        else # it will be a string
          service_links = Hash.new  
          ret = {component_in_ret => {:service_links => service_links}}
        end
        output_target = "#{out_parsed_port[:node_name]}#{Seperators[:node_component]}#{out_parsed_port[:component_name]}"
        service_link = {out_parsed_port[:link_def_ref] => output_target}
        #TODO: this assumes that no component can have two port links with same link def ref
        service_links.merge!(service_link)
        ret 
      end

      def node_bindings_output_hash()
        sp_hash = {
          :cols => [:id,:ref],
          :filter => [:oneof, :id, self[:node].values.map{|n|n[:node_binding_rs_id]}]
        }
        #TODO: may get this info in earlier phase
        node_binding_rows = Model.get_objs(@container_idh.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_binding_id_to_ref = node_binding_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:ref])}
        self[:node].inject(Hash.new) do |h,(node_ref,node_hash)|
          h.merge("#{node_hash[:display_name]}" => node_binding_id_to_ref[node_hash[:node_binding_rs_id]])
        end
      end

    end
  end; end
end
