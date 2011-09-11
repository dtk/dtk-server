require  File.expand_path('link_def/context', File.dirname(__FILE__))
module XYZ
  class LinkDefLink < Model
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

    def attribute_mappings()
      self[:attribute_mappings] ||= (self[:content][:attribute_mappings]||[]).map{|am|AttributeMapping.new(am)}
    end

    def get_context(link_defs_info)
      ret = LinkDefContext.new()
      #TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)} 
      attribute_mappings.each{|am|am.get_context_refs!(ret)}
      
      ret.set_values!(self,link_defs_info)
      ret
    end

    class AttributeMapping < HashObject
      def get_context_refs!(ret)
        ret.add_ref!(self[:input])
        ret.add_ref!(self[:output])
      end
      def ret_link(context)
        input_attr,input_path = get_attribute_with_unravel_path(:input,context)
        output_attr,output_path = get_attribute_with_unravel_path(:output,context)
        raise Error.new("cannot find input_id") unless input_attr
        raise Error.new("cannot find output_id") unless output_attr
        ret = {:input_id => input_attr[:id],:output_id => output_attr[:id]}
        ret.merge!(:input_path => input_path) if input_path
        ret.merge!(:output_path => output_path) if output_path
        ret
      end
     private
      #returns [attribute,unravel_path]
      def get_attribute_with_unravel_path(dir,context)
        index_map_path = nil
        attr = nil
        ret = [attr,index_map_path]
        attr = context.find_attribute(self[dir][:term_index])
        if self[:path]
          #TODO: if treat :create_component_index need to put in here process_unravel_path and process_create_component_index (from link_defs.rb)
          index_map_path = self[:path]
        end
        [attr,index_map_path && AttributeLink::IndexMapPath.create_from_array(index_map_path)]
      end
    end
  end
end
