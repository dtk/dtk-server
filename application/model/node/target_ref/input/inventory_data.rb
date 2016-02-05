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
  class Input
    class InventoryData < self
      r8_nested_require('inventory_data', 'element')

      def initialize(inventory_data_hash)
        super()
        inventory_data_hash.each { |ref, hash| self << Element.new(ref, hash) }
      end

      def create_nodes_from_inventory_data(target)
        target_ref_hash = target_ref_hash()
        target_idh = target.id_handle()
        Model.import_objects_from_hash(target_idh, { node: target_ref_hash }, return_info: true)
      end

      def self.pbuilderid?(node_external_ref)
        node_external_ref ||= {}
        if host_address = node_external_ref[:routable_host_address] || node_external_ref['routable_host_address']
          "#{TargetRef.physical_node_prefix()}#{host_address}"
        end
      end

      private

      def target_ref_hash
        inject({}) { |h, el| h.merge(el.target_ref_hash()) }
      end
    end
  end
end; end; end