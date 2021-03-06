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
module DTK; class Node; class TargetRef
  class Input; class BaseNodes
    class Element
      attr_reader :node, :num_needed
      def initialize(node_info)
        @node = node_info[:node]
        @num_needed = node_info[:num_needed]
        @offset = node_info[:offset] || 1
        @type = :base_node_link
      end

      def add_target_ref_and_ngr!(ret, target, assembly)
        target_ref_hash = target_ref_hash(target, assembly)
        unless target_ref_hash.empty?
          (ret[:node] ||= {}).merge!(target_ref_hash)
          node_group_rel_hash = target_ref_hash.keys.inject({}) do |h, node_ref|
            h.merge(BaseNodes.target_ref_link_hash(@node.id, "/node/#{node_ref}"))
          end
          (ret[:node_group_relation] ||= {}).merge!(node_group_rel_hash)
        end
        ret
      end

      def target_ref_hash(_target, assembly)
        ret = {}
        unless display_name = @node.get_field?(:display_name)
          fail Error.new('Unexpected that that node has no name field')
        end
        external_ref = @node.external_ref
          (@offset...(@offset + @num_needed)).inject({}) do |h, index|
          hash = {
            display_name: ret_display_name(display_name, index: index),
            os_type: @node.get_field?(:os_type),
            type: Type::Node.target_ref_staged,
            external_ref: external_ref.hash()
          }
          ref = ret_ref(display_name, index: index, assembly: assembly)
          h.merge(ref => hash)
        end
      end

      private

      def ret_display_name(name, opts = {})
        TargetRef.ret_display_name(@type, name, opts)
      end

      def ret_ref(name, opts = {})
        "#{@type}--#{ret_display_name(name, opts)}"
      end
    end
  end; end
end; end; end