require  File.expand_path('link_def/parse_serialized_form.rb', File.dirname(__FILE__))
module XYZ
  class LinkDef < Model
    extend LinkDefParseSerializedForm
    def choose_internal_link(possible_links, strategy)
      #TODO: mostly stubbed fn
      ret = nil
      return ret if possible_links.empty?
      raise Error.new("only select_first strataggy currently implemented") unless strategy[:select_first]
      ret = possible_links.first
      if ret[:type] == "internal_external"
        raise Error.new("only strategy internal_external_becomes_internal implemented") unless stratagy[:internal_external_becomes_internal]
      end
      ret
    end
  end
end

