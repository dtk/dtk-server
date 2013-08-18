module DTK
  class ServiceModule; class AssemblyExport
    class V2 < self
     private
      def serialize()
        assembly_hash = assembly_output_hash()
        node_bindings_hash = node_bindings_output_hash()
        temporal_ordering = temporal_ordering_hash()
        ret = SimpleOrderedHash.new(
         [
          {:name => assembly_hash()[:display_name]},
          {:node_bindings => node_bindings_hash}, 
          {:assembly => assembly_hash},
          temporal_ordering && {:workflow => temporal_ordering}
         ].compact)
      end

      def assembly_output_hash()
        ret = SimpleOrderedHash.new()
        #add assembly level attributes
        if assembly_level_attrs = assembly_level_attributes_hash()
          ret[:attributes] = assembly_level_attrs
        end

        #TODO: need to add in component override values
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

          cmps = matching_node[:components]
          i = 0; found = false
          while i < cmps.size
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

      def assembly_level_attributes_hash()
        if attrs = assembly_hash()[:attribute]
          ret = attrs.values.inject(SimpleOrderedHash.new()) do |h,a|
            h.merge(a[:display_name] => AttributeDatatype.convert_value_to_ruby_object(a))
          end
          ret unless ret.empty?
        end
      end

      def temporal_ordering_hash()
        if default_action_task_template = (assembly_hash()[:task_template]||{})[Task::Template.default_task_action()]
          SimpleOrderedHash.new(:assembly_action => "create").merge(default_action_task_template[:content])
        end
      end

      def parse_port_ref(qualified_port_ref,node_ref_to_name)
        port_ref = qualified_port_ref.split("/").last
        p = Port.parse_port_display_name(port_ref)
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
        link_def_ref = out_parsed_port[:link_def_ref]
        if existing_links = service_links[link_def_ref]
          if existing_links.kind_of?(Array)
            existing_links << output_target
          else #existing_links.kind_of?(String)
            #turn into array with existing plus new element
            service_links[link_def_ref] = [service_links[link_def_ref],output_target]
          end
        else
          service_links.merge!(link_def_ref => output_target)
        end
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

      def attr_overrides_output_form(attr_overrides)
        av_list = attr_overrides.values.map{|attr|{attr[:display_name] => attr[:attribute_value]}}.sort{|a,b|a.keys.first <=> b.keys.first}
        SimpleOrderedHash.new(:attributes => SimpleOrderedHash.new(av_list))
      end

    end
  end; end
end
