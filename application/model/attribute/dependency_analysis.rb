module XYZ
  module AttrDepAnalaysisClassMixin
    def dependency_analysis(augmented_attr_list,&block)
      #find attributes that are required
      selected_attrs = augmented_attr_list.select{|a|a[:required]}
      return if selected_attrs.empty?
      attr_ids = selected_attrs.map{|a|a[:id]}.uniq
      sp_hash = {
        :cols => [:function,:index_map,:input_id,:output_id],
        :filter => [:oneof ,:input_id, attr_ids]
      }
      sample_attr = selected_attrs.first
      attr_link_mh = sample_attr.model_handle(:attribute_link)
      links_to_trace = get_objects_from_sp_hash(attr_link_mh,sp_hash)
      
      matches = Array.new
      selected_attrs.each do |attr|
        link = find_matching_link(attr,links_to_trace)
        matches << {:link => link, :attr => attr} if link
      end
      matches.each do |match|
        attr_in = match[:attr]
        link = match[:link]
        output_id =  link[:output_id] 
        attr_out = augmented_attr_list.find{|attr| attr[:id] == output_id}
        debug_flag_unexpected_error(link) if attr_out
        block.call(attr_in,link,attr_out)
      end
    end

   private
    def debug_flag_unexpected_error(link)
      #TODO: handle if warning fires
      unless ["eq","select_one"].include?(link[:function]) or
          (link[:function] == "eq_indexed" and
           ((link[:index_map]||[]).first||{})[:output] == [])
        Log.error("can be error in treatment of matching output to link")
      end
    end

    def find_matching_link(attr,links)
      links.find{|link|link[:input_id] == attr[:id] and index_match(link,attr[:item_path])}
    end
    
    def index_match(link,item_path)
      ret = nil
      case link[:function]
       when "eq","select_one"
        ret = true
       when "eq_indexed"
        if (link[:index_map]||[]).size > 1
          Log.error("not treating index maps with multiple elements")
        end
        if index_map = ((link[:index_map]||[]).first||{})[:input]
          if item_path.kind_of?(Array) and index_map.size == item_path.size
            item_path.each_with_index do |el,i|
              return nil unless el.to_s == index_map[i].to_s
            end
            ret = true
          end 
        end
      end
      ret
    end
  end
end
