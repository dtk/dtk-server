module DTK
  class Attribute
    module DanglingLinksClassMixin
      # aug_attr_links is an array of attribute links (where a specfic one can appear multiple times
      # aug_attr_links has the dangling link info
      # it is augmented with 
      # :input_attribute - attribute that is on input side of attribute link
      # :other_input_link - an atribute link that connects to :input_attribute attribute; can refer to same
      # link as self does
      # 
      def update_and_propagate_attributes_for_delete_links(attr_mh,aug_attr_links,propagate_opts={}) 
        ret = Array.new
        links_delete_info = links_delete_info(aug_attr_links)
        return ret if links_delete_info.empty?
        # find updated attributes
        updated_attrs = UpdateDerivedValues.update_for_delete_links(attr_mh,links_delete_info)
        # propagate these changes; if opts[::add_state_changes] then produce state changes
        propagate_and_optionally_add_state_changes(attr_mh,updated_attrs,propagate_opts)
      end

     private
      def links_delete_info(aug_attr_links)
        ndx_ret = Hash.new
        aug_attr_links.each do |link|
          a_link = link[:other_input_link]
          if a_link[:type] == "external"
            input_attribute = link[:input_attribute]
            attr_id = input_attribute[:id]
            l = ndx_ret[attr_id] ||= UpdateDerivedValues::Delete::LinkInfo.new(input_attribute)
            new_el = {
              :attribute_link_id => a_link[:id],
              :index_map => a_link[:index_map],
            }
            if a_link[:id] == link[:id]
              l.deleted_link = new_el
            else
              l.add_other_link!(new_el)
            end
          end
        end
        ndx_ret.values
      end

    end
  end
end
