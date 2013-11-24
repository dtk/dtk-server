module DTK; class ComponentDSL; class V3
  OMFBase = ComponentDSL::V2::ObjectModelForm                                  
  class ObjectModelForm < OMFBase
    class Component < OMFBase::Component
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

      #processes "link_defs, "dependencies", and "component_order"
      def add_dependent_components!(ret,input_hash,base_cmp,opts={})
        dependencies = dependencies(input_hash,base_cmp,opts)
        ret.set_if_not_nil("dependency",dependencies)
        link_defs = link_defs(input_hash,base_cmp,dependencies,opts)
        ret.set_if_not_nil("link_defs",link_defs)
        ret.set_if_not_nil("component_order",component_order(input_hash))
      end

      def dependencies(input_hash,base_cmp,opts={})
        ret = nil
        if in_dep_cmps = input_hash["dependencies"]
          convert_to_hash_form(in_dep_cmps) do |conn_ref,conn_info|
            choices = Choice.convert_choices(conn_ref,conn_info,base_cmp,opts)
            #can only express necessarily need component on same node; so if multipe choices only doing so iff all are internal
            unless choices.find{|choice|not choice.is_internal?()}
              #TODO: make sure it is ok to just pick one of these
              choice = choices.first
              ret ||= OutputHash.new
              add_dependency!(ret,choice.dependent_component(),base_cmp)
            end
          end
        end
        ret
      end

      def link_defs(input_hash,base_cmp,dependencies,opts={})
        ret = nil
        if in_link_defs = input_hash["link_defs"]
          pp [:debug,in_link_defs]
        end
        ret
      end
=begin        

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
=end

    end
  end
end; end; end

