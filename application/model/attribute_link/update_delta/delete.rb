module DTK; class AttributeLink; class UpdateDelta
  # for processing deleting of links
  class Delete < self
    r8_nested_require('delete', 'link_info')
    r8_nested_require('delete', 'index')

    def self.links_delete_info(aug_attr_links)
      ndx_ret = {}
      aug_attr_links.each do |link|
        a_link = link[:other_input_link]
        if a_link[:type] == 'external'
          input_attribute = link[:input_attribute]
          attr_id = input_attribute[:id]
          l = ndx_ret[attr_id] ||= LinkInfo.new(input_attribute)
          new_el = {
            attribute_link_id: a_link[:id],
            index_map: a_link[:index_map]
          }
          if a_link[:id] == link[:id]
            l.add_deleted_link!(new_el)
          else
            l.add_other_link!(new_el)
          end
        end
      end
      ndx_ret.values
    end

    def self.update_attribute(attr_mh, link_info)
      Index.update_indexes!(attr_mh, link_info)
    end

    private


  end
end; end; end
