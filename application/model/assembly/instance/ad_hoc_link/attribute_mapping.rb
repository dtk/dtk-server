#TODO: rather than includeing ~/server/utils/internal/component_dsl/adapters/v2/convert_to_object_model_form.rb
#put common routines in shared place
module DTK
  class Assembly::Instance
    class AdHocLink
      class AttributeMapping
        def self.add(assembly,port_link_idh,am_input_form)
          #TODO: stub
          base_cmp = nil
          dep_cmp = nil
          ComponentDSL.convert_attribute_mapping(am_input_form,base_cmp,dep_cmp)
        end
      end
    end
  end
end
