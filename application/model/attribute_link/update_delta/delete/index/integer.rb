#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class AttributeLink::UpdateDelta::Delete
  class Index
    class Integer < self
      # splice out the values in input array from the deleted links and renumber on the other links
      def process!
        splice_out!
      end

      private
      
      IndexPositionInfo = Struct.new(:current_pos, :new_pos, :link)
      def splice_out!
        input_attribute = @link_info.input_attribute

        # for other links to facilitate renumbering maintain a renumbering_mapping
        index_pos_info_array = @link_info.other_links.map do |link|
        current_pos = integer_index(link)
          IndexPositionInfo.new(current_pos, current_pos, link)
        end
        
        # iterating over delete_positions; reversing order so dont have to renumber this
        delete_positions = @link_info.deleted_links.map { |link| integer_index(link) }.sort { |a, b| b <=> a }

        ret = update_attributes do |existing_array_attr_val|
          new_val = existing_array_attr_val.dup?
          delete_positions.each do |pos_to_delete|
            new_val.delete_at(pos_to_delete)
            index_pos_info_array.each do |other_link_info|
              if other_link_info.new_pos > pos_to_delete
                other_link_info.new_pos -= 1
              end
            end
          end
          new_val
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

      def integer_index(link)
        input_index = input_index(link)
        Index.index_has_type?(:integer, input_index) || Index.error_msg_link_def_index(input_index)
      end

    end
  end
end; end