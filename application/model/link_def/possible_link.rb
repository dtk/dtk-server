module XYZ
  class LinkDefPossibleLink < Model
    def self.create_from_serialized_form(link_def_idh,possible_link)
      name = possible_link[:name]
      row = {
        :link_def_id_id => libk_def_idh.get_id(),
        :display_name => name,
        :ref => name
      }
      possible_link_idh = create_from_row(model_handle,row)
      (possible_link[:attribute_mappings]||[]).each do |attr_mapping|
        LinkDefAttributeMapping.create_from_serialized_form(possible_link_idh,attr_mapping)
      end                                                        
      (possible_link[:events]||[]).each do |event|
        LinkDefEvent.create_from_serialized_form(possible_link_idh,event)
      end                                                        
    end
  end
end
