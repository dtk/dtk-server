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
  class PortLink::ComponentInfo
    class Endpoint
      def initialize(aug_ports)
        fail Error, "Unexpected that aug_ports is empty" if aug_ports.empty?
        @aug_ports = aug_ports
      end

      attr_reader :aug_ports      

      def component
        # if multiple ports they will have same node_component
        self.aug_ports.first[:component] || fail("Unexpected that aug_ports.first[:component] is nil")
      end
      
      def node_id
        # if multiple ports they will have same node_node_id
        self.aug_ports.first[:node_node_id] || fail("Unexpected that aug_ports.first[:node_node_id] is nil")
      end

      def is_assembly_wide_node?
        if @is_assembly_wide_node.nil?
          @is_assembly_wide_node = !! self.node.is_assembly_wide_node?
        else
          @is_assembly_wide_node
        end
      end

      def link_type
        # if multiple ports they will have same link_type
        self.aug_ports.first[:link_type] || fail("Unexpected that aug_ports.first[:link_type] is nil")
      end

      protected

      def node
        @node ||= self.component.model_handle(:node).createIDH(id: self.node_id).create_object
      end

    end
  end
end

