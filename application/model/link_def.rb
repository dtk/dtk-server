module XYZ
  class LinkDef < Model
    def self.create_from_serialized_form(component_idh,link_def)
      name => link_def[:name]
      row = {
        :component_component_id => component_idh.get_id(),
        :display_name => name,
        :ref => name
      }
      link_def_idh = create_from_row(model_handle,row)
      link_def[:possible_links].each_with_index do |possible_link,pos|
        LinkDefPossibleLink.create_from_serialized_form(link_def_idh,possible_link.merge(:position => pos))
      end                                                        
    end
  end
end

