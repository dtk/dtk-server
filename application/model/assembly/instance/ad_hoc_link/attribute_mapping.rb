module DTK
  class Assembly::Instance
    class AdHocLink
      class AttributeMapping
        def self.add(assembly,port_link,am_input_form)
          port_link_info = port_link.get_obj(:cols => [:augmented_ports])
          base_cmp = port_link_info[:input_component][:component_type]
          dep_cmp = port_link_info[:output_component][:component_type]
          ComponentDSL.convert_attribute_mapping(am_input_form,base_cmp,dep_cmp)
        end
      end
    end
  end
end
