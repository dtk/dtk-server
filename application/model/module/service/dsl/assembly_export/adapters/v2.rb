module DTK
  class ServiceModule; class AssemblyExport
    class V2 < self
     private
      def serialize()
        assembly_hash = assembly_output_hash()
        node_bindings_hash = node_bindings_output_hash()
        temporal_ordering = temporal_ordering_hash()
        dsl_version = dsl_version?()
        SimpleOrderedHash.new(
         [
          {:name => assembly_hash()[:display_name]},
          dsl_version && {:dsl_version => dsl_version},
          {:node_bindings => node_bindings_hash}, 
          {:assembly => assembly_hash},
          temporal_ordering && {:workflow => temporal_ordering}
         ].compact)
      end

      def assembly_output_hash()
        ret = SimpleOrderedHash.new()
        # add assembly level attributes
        if assembly_level_attrs = assembly_level_attributes_hash()
          ret[:attributes] = assembly_level_attrs
        end

        # add nodes and components
        node_ref_to_name = Hash.new
        ret[:nodes] = self[:node].inject(SimpleOrderedHash.new()) do |h,(node_ref,node_hash)|
          node_name = node_hash[:display_name]
          node_ref_to_name[node_ref] = node_name
          cmp_info = node_hash[:component_ref].values.map{|cmp|component_output_form(cmp)}
          node_hash_output = SimpleOrderedHash.new()
          if node_attrs_output = node_attributes_output_form?(node_hash[:attribute])
            node_hash_output.merge!(:attributes => node_attrs_output)
          end
          node_hash_output.merge!(:components => cmp_info)
          h.merge(node_name => node_hash_output)
        end

        # add in port links
        self[:port_link].values.each do |pl|
          in_parsed_port = parse_port_ref(pl["*input_id"],node_ref_to_name)
          out_parsed_port  = parse_port_ref(pl["*output_id"],node_ref_to_name)
          unless matching_node = ret[:nodes][in_parsed_port[:node_name]]
            raise Error.new("Cannot find matching node for input port")
          end

          cmps = matching_node[:components]
          i = 0; found = false
          while i < cmps.size
            if match_component?(cmps[i],in_parsed_port)
              cmps[i] = add_component_link_to_cmp(cmps[i],out_parsed_port)
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
          convert_opts = {:value_field => :value_asserted}
          ret = attrs.values.inject(SimpleOrderedHash.new()) do |h,a|
            h.merge(a[:display_name] => Attribute::Datatype.convert_value_to_ruby_object(a,convert_opts))
          end
          ret unless ret.empty?
        end
      end

      def node_attributes_output_form?(attrs)
        ret = (attrs||Hash.new).values.inject(Hash.new) do |h,attr|
          val = attr[:value_asserted]
          val.nil? ? h : h.merge(attr[:display_name] => val)
        end
        ret unless ret.empty?
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
        ret = {:node_name => node_ref_to_name[node_ref], :component_name => component_name, :link_def_ref => p[:link_def_ref]}
        if title = p[:title]
          ret.merge!(:title => title)
        end
        ret
      end

      def match_component?(component_in_ret,parsed_port)
        match_term = 
          if component_in_ret.kind_of?(Hash)
            component_in_ret.keys.first
          else # it will be a string
            component_in_ret
          end
        parsed_port_match_term = parsed_port[:component_name]
        if title = parsed_port[:title]
          parsed_port_match_term = "#{parsed_port[:component_name]}[#{title}]"
        else
        end
        match_term == parsed_port_match_term
      end

      def add_component_link_to_cmp(component_in_ret,out_parsed_port)
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
            # turn into array with existing plus new element
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
        # TODO: may get this info in earlier phase
        node_binding_rows = Model.get_objs(@container_idh.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_binding_id_to_ref = node_binding_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:ref])}
        self[:node].inject(Hash.new) do |h,(node_ref,node_hash)|
          h.merge("#{node_hash[:display_name]}" => node_binding_id_to_ref[node_hash[:node_binding_rs_id]])
        end
      end

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:display_name])
        if attr_overrides_output_form = attr_overrides_output_form(component_hash[:attribute_override])
          {name => attr_overrides_output_form}
        else
          name 
        end
      end

      def attr_overrides_output_form(attr_overrides)
        ret = nil
        return ret unless attr_overrides
        av_list = attr_overrides.values.map do |attr|
          unless attr.is_title_attribute()
            {attr[:display_name] => attr_override_value_output_form(attr)}
          end
        end.compact.sort{|a,b|a.keys.first <=> b.keys.first}
        (!av_list.empty?)  && SimpleOrderedHash.new(:attributes => SimpleOrderedHash.new(av_list))
      end

      def attr_override_value_output_form(attr)
        if raw_val = attr[:attribute_value]
          converted_val = 
            case attr[:data_type]
              when 'boolean'
                if raw_val == 'true'
                  true
                elsif raw_val == 'false'
                  false
                end
              when 'integer'
                raw_val.to_i
            end
          converted_val || raw_val
        end
      end

    end
  end; end
end
