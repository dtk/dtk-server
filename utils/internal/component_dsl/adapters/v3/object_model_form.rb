module DTK; class ComponentDSL; class V3
  Base = ComponentDSL::V2::ObjectModelForm                                  
  class ObjectModelForm < Base
    class Component < Base::Component
     private
      def body(input_hash,cmp)
        pp [:in,self.class]
        ret = OutputHash.new
        cmp_type = ret["display_name"] = ret["component_type"] = qualified_component(cmp)
        ret["basic_type"] = "service"
        ret.set_if_not_nil("description",input_hash["description"])
        external_ref = external_ref(input_hash.req(:external_ref),cmp)
        ret["external_ref"] = external_ref
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(external_ref))
        add_attributes!(ret,cmp_type,input_hash)
        opts = Hash.new
        add_dependent_components!(ret,input_hash,cmp_type,opts)
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash["includes"]))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        ret
      end

      def dynamic_default_variable?(info)
        default_indicates_dynamic_default_variable?(info)
      end
      def value_asserted(info) 
        unless default_indicates_dynamic_default_variable?(info)
          info["default"] 
        end
      end
      def default_indicates_dynamic_default_variable?(info)
        info["default"] == ExtRefDefaultPuppetHeader
      end
      ExtRefDefaultPuppetHeader = 'external_ref(puppet_header)'

      def add_attr_data_type_attrs!(attr_props,info)
        type = info.req(:type)
        if AutomicTypes.include?(type)
          attr_props.merge!("data_type" => type)
        elsif type =~ /^array\((.+)\)$/
          scalar_type = $1
          if ScalarTypes.include?(scalar_type)
            semantic_type = {":array" => scalar_type} 
            attr_props.merge!("data_type" => "json","semantic_type_summary" => type,"semantic_type" => semantic_type)
          end
        end
        unless attr_props["data_type"]
          raise ParsingError.new("Ill-formed attribute data type (?1)",type)
        end
        attr_props
      end
      ScalarTypes = %w{integer string boolean}
      AutomicTypes = ScalarTypes + %w{json}

      #partitions into link_defs, "dependency", and "component_order"
      def get_dependent_config(input_hash,base_cmp,opts={})
        ret = Hash.new
        link_defs  = Array.new
        if in_dep_cmps = input_hash["depends_on"]
          convert_to_hash_form(in_dep_cmps) do |conn_ref,conn_info|
            choices = Choice.convert_choices(conn_ref,conn_info,base_cmp,opts)

            #determine if create a link def and/or a dependency
            #creaet a dependency if just single choice and base adn depnedncy on same node
            #TODO: only handling addition of dependencies if single choice; consider adding just temporal if multiple choices
            if choices.size == 1 
              choice = choices.first
              if choice.is_internal?()
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr,choice.dependent_component(),base_cmp)
              end
            end

            #create link defs if there are multiple choices or theer are attribute mappings
            if choices.size > 1 or (choices.size == 1 and choices.first.has_attribute_mappings?())
              link_def = OutputHash.new(
                "type" => get_connection_label(conn_ref,conn_info),
                "required" =>  true, #will be putting optional elements under a key that is peer to 'depends_on'
                "possible_links" => choices.map{|choice|choice.possible_link()}
              )
              link_def.set_if_not_nil("description",conn_info["description"])
              link_defs << link_def
            end
          end
        end
        ret[:link_defs] = link_defs unless link_defs.empty?
        #TODO: is this redundant with 'order', which just added
        if component_order = component_order(input_hash)
          ret[:component_order] = component_order
        end
        ret
      end
    end
  end
end; end; end

