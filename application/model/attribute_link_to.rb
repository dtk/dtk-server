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
module DTK
  class AttributeLinkTo < Model
    def self.common_columns
      [:id, :group_id, :display_name, :component_red, :description]
    end

    def self.get_for_attribute_id(mh, attribute_id)
      sp_hash = {
        cols: [:id, :ref, :display_name, :component_ref, :attribute_id, :description],
        filter: [:eq, :attribute_id, attribute_id]
      }
      get_objs(mh, sp_hash)
    end

    def self.get_for_attribute_ids(mh, attribute_ids)
      sp_hash = {
        cols: [:id, :ref, :display_name, :component_ref, :attribute_id, :description],
        filter: [:oneof, :attribute_id, attribute_ids]
      }
      get_objs(mh, sp_hash)
    end

    def self.create_or_update(parent_mh, links_to)
      to_add     = []
      to_delete  = []
      existing   = []
      attr_ids   = links_to.map{ |lf| lf[:attribute_id] }
      link_to_mh = parent_mh.create_childMH(:attribute_link_to)
      links      = get_for_attribute_ids(link_to_mh, attr_ids)

      links_to.each do |link_to|
        matching_links = links.select{ |link| link[:attribute_id] == link_to[:attribute_id]}
        if matching_links.empty?
          to_add << link_to
        else
          matching_link_names = matching_links.map{ |ml| ml[:display_name] }
          if matching_link_names.include?(link_to[:display_name])
            existing << link_to
          else
            to_add << link_to
          end
        end
      end

      links.each do |link|
        if to_add.find { |ta| ta[:display_name] == link[:display_name] && ta[:attribute_id] == link[:attribute_id] }
          next
        elsif existing.find { |ex| ex[:display_name] == link[:display_name] && ex[:attribute_id] == link[:attribute_id] }
          next
        else
          to_delete << link
        end
      end

      Model.delete_instances(to_delete.map{ |td| td.id_handle })
      Model.create_from_rows(link_to_mh, to_add, convert: true)
    end
  end
end
