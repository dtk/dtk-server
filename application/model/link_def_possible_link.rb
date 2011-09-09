require  File.expand_path('link_def/context', File.dirname(__FILE__))
module XYZ
  class LinkDefPossibleLink < Model
    include LinkDefParseSerializedForm
    def self.create_from_serialized_form(link_def_idh,possible_links)
      rows = parse_possible_links(possible_links)
      link_def_id = link_def_idh.get_id()
      rows.each_with_index do |r,i|
        r[:position] = i+1
        r[:link_def_id] = link_def_id
      end
      create_from_rows(model_handle,rows)
    end

    def get_context()
      ret = LinkDefContext.new()
      content = self[:content]
      #TODO: add back in commented out parts
     # constraints = content[:constraints]
     # constraints.each{|cnstr|cnstr.get_context_refs!(ret)} if constraints
      ams = content[:attribute_mappings]
      ams.each{|am|AttributeMapping.new(am).get_context_refs!(ret)} if ams
#      ret.set_values!(self,local_cmp,remote_cmp)
      ret
    end

    class AttributeMapping < HashObject
      def get_context_refs!(ret)
        ret.add_ref!(self[:input])
        ret.add_ref!(self[:output])
      end
    end
  end
end
