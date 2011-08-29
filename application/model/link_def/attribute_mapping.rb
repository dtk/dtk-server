require  File.expand_path('parse_serialized_form', File.dirname(__FILE__))
module XYZ
  class LinkDefAttributeMapping < Model
    include LinkParseSerializedForm
    def self.create_from_serialized_form(possible_link_idh,attr_mappings,context)
      parsed_mappings = attr_mappings.map{|mapping|parse_attribute_mapping(mapping)
    end
  end
end
