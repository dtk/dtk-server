module XYZ
  module AttrDepAnalaysisClassMixin
    def dependency_analysis(aug_attr_list,&block)
      #find attributes that are required
      return if aug_attr_list.empty?
      attr_ids = aug_attr_list.map{|a|a[:id]}.uniq
      sp_hash = {
        :cols => [:function,:index_map,:input_id,:output_id],
        :filter => [:oneof ,:input_id, attr_ids]
      }
      sample_attr = aug_attr_list.first
      attr_link_mh = sample_attr.model_handle(:attribute_link)
      links_to_trace = get_objects_from_sp_hash(attr_link_mh,sp_hash)
      
      matches = Array.new
      aug_attr_list.each do |attr|
        link = find_matching_link(attr,links_to_trace)
        matches << {:link => link, :attr => attr} if link
      end
      matches.each do |match|
        attr_in = match[:attr]
        link = match[:link]
        attr_out = find_matching_output_attr(aug_attr_list,attr_in,link)
        block.call(attr_in,link,attr_out)
      end
    end

   private
    def find_matching_output_attr(aug_attr_list,attr_in,link)
      #TODO: to make moer efficient have other ind_matching_output_attr__[link_fn]
      return find_matching_output_attr__eq_indexed(aug_attr_list,attr_in,link) if link[:function] == "eq_indexed"
      ret = nil
      output_id =  link[:output_id] 
      ret = aug_attr_list.find do |attr|
        if attr[:id] == output_id
          case link[:function]
           when "eq" then true
           when "select_one" 
            out_item_path = attr[:item_path]
            out_item_path and (attr_in[:item_path] == out_item_path[1,out_item_path.size-1])
          else
           Log.error("not treated when link function is #{link[:function]}")
            nil
          end
        end
      end

      #TODO: remove these debug statements
      ##l = lambda{|a| [a[:display_name],a[:node][:display_name],a[:item_path]]}
      ##pp [link[:function],link[:index_map],l.call(attr_in), ret && l.call(ret)]

      ret
    end

    def find_matching_output_attr__eq_indexed(aug_attr_list,attr_in,link)
      if not (link[:index_map]||[]).size == 1
        Log.error("not treating index maps with multiple elements")
        return nil
      end
      link_output_index_map =  link[:index_map].first[:output]||[]
      output_id = link[:output_id]
      aug_attr_list.find do |attr|
        attr[:id] == output_id and matching_index_maps?(link_output_index_map,attr[:item_path]) 
      end
    end

    def matching_index_maps?(index_map,item_path)
      return true if index_map.empty?
      return nil unless index_map.size == item_path.size
      index_map.each_with_index do |el,i|
        return nil unless item_path[i] == (el.kind_of?(String) ? el.to_sym : el) 
      end
      true
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
