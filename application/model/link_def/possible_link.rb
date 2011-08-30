require  File.expand_path('parse_serialized_form', File.dirname(__FILE__))
module XYZ
  class LinkDefPossibleLink < Model
    include LinkDefParseSerializedForm
    def self.create_from_serialized_form(component,link_def_idh,possible_link)
      component.update_object!(:library_library_id)
      remote_component_name = possible_link.keys.first
      link_info = possible_link.values.first

      #find the remote_component_id
      sp_hash = {
        :cols => [:id,:component_type]
        :filter => [:and, [:eq, :component_type, remote_component_name],
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
      parsed_events = parse_events(possible_link[:events]||)
      LinkDefEvent.create_from_serialized_form(possible_link_idh,parsed_events) unless parsed_events.empty?
      attr_mappings = possible_link[:attribute_mappings]||[]
      context = {
        :local_component => component,
        :remote_component => remote_component,
        :parsed_events => parsed_events
      }
      LinkDefAttributeMapping.create_from_serialized_form(possible_link_idh,attr_mappings,context) unless attr_mappings.empty?
    end
  end
end
