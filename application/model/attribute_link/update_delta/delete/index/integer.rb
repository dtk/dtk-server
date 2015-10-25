module DTK; class AttributeLink::UpdateDelta::Delete
  class Index
    class Integer < self
      # splice out the values in input array from the deleted links and renumber on the other links
      def process!
        splice_out
      end

      private
      
      IndexPositionInfo = Struct.new(:current_pos, :new_pos, :link)
      def splice_out
        ret = nil
        input_attribute = @link_info.input_attribute

        # for other links to facilitate renumbering maintain a renumbering_mapping
        index_pos_info_array = @link_info.other_links.map do |link|
        current_pos = array_integer(input_index(link))
          IndexPositionInfo.new(current_pos, current_pos, link)
        end
        
        # will be interating over delete_positions; reversing order so dont have to renumber this
        delete_positions = @link_info.deleted_links.map do |link|
          array_integer(input_index(link))
        end.sort { |a, b| b <=> a }
        Model.select_process_and_update(@attr_mh, [:id, :value_derived], [input_attribute[:id]]) do |rows|
        # will only be one row;
          row = rows.first
          val = row[:value_derived]
          ret = { id: row[:id], old_value_derived: val.dup? }
          delete_positions.each do |pos_to_delete|
            val.delete_at(pos_to_delete)
            index_pos_info_array.each do |other_link_info|
              if other_link_info.new_pos > pos_to_delete
                other_link_info.new_pos -= 1
              end
            end
          end
          ret.merge!(value_derived: val)
          [row] #row with changed :value_derived
        end
        
        renumber_links?(index_pos_info_array)
        
        ret
      end
      
      def renumber_links?(index_pos_info_array)
        rows_to_update = []
        index_pos_info_array.map do |index_pos_info|
          if index_pos_info.current_pos != index_pos_info.new_pos
            link = index_pos_info.link
            new_index_map = [{ output: output_index(link), input: [index_pos_info.new_pos] }]
            rows_to_update << { id: link[:attribute_link_id], index_map: new_index_map }
          end
        end
        unless rows_to_update.empty?
          Model.update_from_rows(@attr_mh.createMH(:attribute_link), rows_to_update)
        end
      end

      def array_integer(input_index)
        Index.index_has_type?(:integer, input_index) || Index.error_msg_link_def_index(input_index)
      end

    end
  end
end; end
