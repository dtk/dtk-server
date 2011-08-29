module XYZ
  class LinkDefPossibleLink < Model
    def self.create_from_serialized_form(component,link_def_idh,possible_link)
      component.update_object!(:library_library_id)
      remote_component_name = possible_link.keys.first
      link_info = possible_link.values.first

      #find the remote_component_id
      sp_hash = {
        :cols => [:id]
        :filter => [:and, [:eq, :display_name, remote_component_name],
                    [:eq, :library_library_id, component[:library_library_id]]]
      }
      remote_component = Model.get_objs(component.model_handle,sp_hash).first
      unless remote_component
        raise Error.new("cannot find remote component matching #{remote_component_name}")
      end
      name = remote_component_name
      row = {
        :link_def_id_id => link_def_idh.get_id(),
        :display_name => name,
        :ref => name,
        :position => link_info[:position],
        :remote_component_id => remote_component[:id]
      }
      possible_link_idh = create_from_row(model_handle,row)
      events = possible_link[:events]||[]
      LinkDefEvent.create_from_serialized_form(possible_link_idh,events) unless events.empty?
      attr_mappings = possible_link[:attribute_mappings]||[]
      context = {
        :local_component_idh => component.id_handle,
        :remote_component => remote_component.id_handle,
        :events => events
      }
      LinkDefAttributeMapping.create_from_serialized_form(possible_link_idh,attr_mappings,context) unless attr_mappings.empty?
    end
  end
end
