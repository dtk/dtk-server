require  File.expand_path('parse_serialized_form', File.dirname(__FILE__))
module XYZ
  class LinkDefEvent < Model
    include LinkDefParseSerializedForm
    def self.create_from_serialized_form(possible_link_idh,events)
      parsed_events = parse_events(events)
      #TODO: stub
      parsed_events
    end
  end
end
