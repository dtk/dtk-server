require  File.expand_path('parse_serialized_form', File.dirname(__FILE__))
module XYZ
  class LinkDefAttributeMapping < Model
    include LinkDefParseSerializedForm
    def self.create_from_serialized_form(possible_link_idh,attr_mappings,context)
      parsed_mappings = attr_mappings.map{|mapping|parse_attribute_mapping(mapping)}
      #either an attribute shoudl refer to existing attribute or to one in a create action in an event
      created_atts = parse_events_for_created_attributes(context[:events])
    end
  end
end
