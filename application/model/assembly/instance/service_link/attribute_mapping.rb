module DTK
  class Assembly::Instance
    class ServiceLink
      class AttributeMapping
        def self.add(assembly,port_link,am_input_form)
          port_link_info = port_link.get_obj(:cols => [:augmented_ports])
          base_cmp = port_link_info[:input_component]
          dep_cmp = port_link_info[:output_component]

          #TODO: right now leverging code that adds attribute links from a link_def_link object
          #get attribute mapping into form used in link_def_link
          am_serialized_form = ComponentDSL.convert_attribute_mapping(am_input_form,base_cmp[:component_type],dep_cmp[:component_type])
          attribute_mapping = LinkDef.parse_serialized_form_attribute_mapping(am_serialized_form)
          link_def_link_hash = {
            :local_component_type => base_cmp[:component_type],
            :remote_component_type => dep_cmp[:component_type],
            :content => {
              :attribute_mappings => [attribute_mapping]
            }
          }
          link_def_link_stub = LinkDefLink.create_stub(assembly.model_handle(:link_def_link),link_def_link_hash)
          link_def_link_stub.process(assembly.get_target_idh(),[base_cmp,dep_cmp])
        end
      end
    end
  end
end
