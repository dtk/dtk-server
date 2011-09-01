require  File.expand_path('link_def/parse_serialized_form.rb', File.dirname(__FILE__))
module XYZ
  class LinkDef < Model
    extend LinkDefParseSerializedForm
  end
end

