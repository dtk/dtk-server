module DTK
  class Assembly::Instance
    class AdHocLink
      class AttributeMapping
        def self.add(assembly,port_link,am_input_form)
          port_link_info = port_link.get_obj(:cols => [:augmented_ports])
          base_cmp_type = port_link_info[:input_component][:component_type]
          dep_cmp_type = port_link_info[:output_component][:component_type]

          #TODO: right now leverging code that adds attribute links from a link_def_link object
          #get attribute mapping into form used in link_def_link
          am_serialized_form = ComponentDSL.convert_attribute_mapping(am_input_form,base_cmp_type,dep_cmp_type)
          attribute_mapping = LinkDef.parse_serialized_form_attribute_mapping(am_serialized_form)
          pp attribute_mapping
        end
      end
    end
  end
end
