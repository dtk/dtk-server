module XYZ
  class LinkDef < Model
    def self.create_from_serialized_form(component,link_def)
      name => link_def[:type] #TODO: may change serialized form field
      row = {
        :component_component_id => component.id(),
        :display_name => name,
        :ref => name
      }
      row.merge!(:required => link_def[:required]) if link_def.has_key?(:required)
      link_def_idh = create_from_row(model_handle,row)

      LinkDefPossibleLink.create_from_serialized_form(link_def_idh,possible_links)
    end
  end
end

