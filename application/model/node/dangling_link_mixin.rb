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
module DTK; class Node
  module DanglingLink
    module Mixin
      def update_dangling_links(filter = {})
        ret = []
        cmp_idhs = filter[:component_idhs]
        dangling_links = cmp_idhs ? get_dangling_links__for_component(cmp_idhs) : get_dangling_links__for_node()
        return ret if dangling_links.empty?
        aug_dangling_links = dangling_links.map do |r|
          r[:attribute_link].merge(r.hash_subset(:input_attribute, :other_input_link))
        end
        attr_mh = model_handle_with_auth_info(:attribute)
        AttributeLink.update_for_delete_links(attr_mh, aug_dangling_links, add_state_changes: true)
      end

      private

      def get_dangling_links__for_node
        get_objs(cols: [:dangling_input_links_from_components]) +
          get_objs(cols: [:dangling_input_links_from_nodes])
      end

      def get_dangling_links__for_component(cmp_idhs)
        # TODO: more efficient way of doing this ratehr than using the same methods used for node; instead can
        # index from component
        cmp_ids = cmp_idhs.map(&:get_id)
        ret = get_objs(cols: [:dangling_input_links_from_components]).select { |r| cmp_ids.include?(r[:component][:id]) }
        port_link_ids = Component::Instance.get_port_links(cmp_idhs).map { |r| r[:id] }
        unless port_link_ids.empty?
          ret += get_objs(cols: [:dangling_input_links_from_nodes]).select do |r|
            port_link_ids.include?(r[:attribute_link][:port_link_id])
          end
        end
        ret
      end
    end
  end
end; end